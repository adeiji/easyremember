//
//  NotificationsManager.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/4/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import DephynedFire
import RxSwift
import FirebaseFirestore

class NotificationsManager {
        
    let disposeBag = DisposeBag()
    
    static let shared = NotificationsManager()
    
    /**
     Delete a notification with the given Id
     - parameter id: The unique id for this notification on Firebase.  **This is the documentId of the object on Firebase**
     
     - Todo: I need to remove the document query on deleteDocuments method
     - returns: An observable of type boolean, if true than that means the notification was deleted
     */
    static func deleteNotificationWithId (_ id: String) -> Observable<Bool> {
        return Observable.create { (observer) -> Disposable in
            FirebasePersistenceManager.deleteDocuments(withCollection: GRNotification.Keys.kCollectionName, documentId: id) { (success, error) in
                if let error = error {
                    observer.onError(error)
                    observer.onCompleted()
                    return
                }
                
                observer.onNext(success)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    enum SyncingError: Error {
        case NoNotifications
    }
    
    func getNotificationWithId (_ id: String, completion: @escaping (GRNotification?) -> Void) {
        FirebasePersistenceManager.getDocumentById(forCollection: GRNotification.Keys.kCollectionName, id: id)
            .subscribe { [weak self] (event) in
                guard let _ = self else { return }
                
                if let element = event.element {
                    let notification = FirebasePersistenceManager.generateObject(fromFirebaseDocument: element) as GRNotification?
                    completion(notification)
                    return
                }
                
                completion(nil)
        }.disposed(by: self.disposeBag)
    }
    
    /**
     Get all the notifications for this device
     
     - parameter deviceId: The Unique Id for this device, you can retrieve it using UtilityFunctions.deviceId()
     */
    static func getNotifications (deviceId: String) -> Observable<[GRNotification]> {
        
        var observables = [
            FirebasePersistenceManager.getDocumentsAsObservable(withCollection: GRNotification.Keys.kCollectionName, queryDocument: [GRNotification.Keys.kDeviceId: deviceId])
        ]
        
        UtilityFunctions.syncIds()?.forEach({ (syncId) in
            observables.append(FirebasePersistenceManager.searchForDocumentsAsObservable(value: syncId.lowercased(), collection: GRNotification.Keys.kCollectionName, key: GRNotification.Keys.kDeviceId))
        })
        
        return Observable.merge(observables).map({ FirebasePersistenceManager.getObjectsFromFirebaseDocuments(fromFirebaseDocuments: $0) as [GRNotification]? ?? [] })
    }
    
    func setNextNotificationToActive (creationDate: TimeInterval) {
        
        let db = Firestore.firestore()
        let notificationsRef = db.collection(GRNotification.Keys.kCreationDate)
        
        notificationsRef.whereField(GRNotification.Keys.kRemembered, isEqualTo: false)
        notificationsRef.whereField(GRNotification.Keys.kActive, isEqualTo: false)
        notificationsRef.limit(to: 1)
        
        notificationsRef.getDocuments { (snapshot, error) in
            guard let snapshot = snapshot else { return }
            let firebaseDocuments = FirebasePersistenceManager.convertSnapshotToFirebaseDocuments(querySnapshot: snapshot)
            guard let notification = (FirebasePersistenceManager.getObjectsFromFirebaseDocuments(fromFirebaseDocuments: firebaseDocuments) as [GRNotification]?)?.first else { return }
            NotificationsManager.toggleNotification(notificationId: notification.id, active: true, remembered: false).subscribe().disposed(by: self.disposeBag)            
        }
    }
    
    func rememberNotificationWithId (_ notificationId: String) {
        NotificationsManager.toggleNotification(notificationId: notificationId, active: false, remembered: true).subscribe { [weak self] (event) in
            guard let _ = self else { return }
            if event.isCompleted { return }
            if event.element == true {
                AnalyticsManager.logMethodEvent(name: "User selected remember through a notification for notification with ID: \(notificationId)" )
            }
        }.disposed(by: self.disposeBag)
    }
    
    /**
     Toggle this notification as active or inactive
     
     - parameters:
        - notificationId: The id for this notification, it should be the document Id for the notification in the Notification collection
        - active: The active state of this notification, this needs to be the state that you want to be saved on the server.  So if you want this to now be an active notification you need to set **active** to **true**
     */
    static func toggleNotification (notificationId: String, active: Bool, remembered: Bool) -> Observable<Bool> {
        
        return Observable.create { (observer) -> Disposable in
            
            FirebasePersistenceManager.updateDocument(withId: notificationId, collection: GRNotification.Keys.kCollectionName, updateDoc: [
                GRNotification.Keys.kActive: active,
                GRNotification.Keys.kRemembered: remembered
            ]) { (error) in
                if let error = error {
                    observer.onError(error)
                    observer.onCompleted()
                    return
                }
                
                // Successful
                observer.onNext(true)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    func saveNotifications (_ notifications: [GRNotification], completed: @escaping (Bool) -> Void ) {
        var observables = [Observable<GRNotification?>]()
        
        notifications.forEach { [weak self] (notification) in
            guard let self = self else { return }
            
            observables.append(self.saveNotification(title: notification.caption, description: notification.description, deviceId: notification.deviceId, language: notification.language, bookTitle: notification.bookTitle))
        }
                        
        Observable.merge(observables).takeLast(1).subscribe { [weak self] (event) in
            
            guard let _ = self else { return }
            
            if event.isCompleted {
                completed(true)
            }
            
        }.disposed(by: self.disposeBag)
    }
    
    /** Update a notification*/
    func updateNotification (notification: GRNotification) -> Observable<Bool> {
        do {
            let data = try JSONEncoder().encode(notification)
            let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any]
            
            return Observable.create { (observable) -> Disposable in
                FirebasePersistenceManager.updateDocument(withId: notification.id, collection: GRNotification.Keys.kCollectionName, updateDoc: dict) { (error) in
                    
                    if let error = error {
                        observable.onError(error)
                        observable.onCompleted()
                        return
                    }
                    
                    observable.onNext(true)
                    observable.onCompleted()
                }
                return Disposables.create()
            }
                        
        } catch {
            assertionFailure("Baaka, the GRNotification object is not Encodable, why?")
            print(error.localizedDescription)
            return .empty()
        }
        
        
    }
    
    func saveNotification (title: String, description: String, deviceId:String, language:String? = nil, bookTitle:String? = nil, tags:[String]? = nil) -> Observable<GRNotification?> {
        
        // 86400 is the amount of seconds in a day
        let expirationDate = Date().timeIntervalSince1970.advanced(by: 86400 * 7)
        var notificationData:[String:Any] = [
            GRNotification.Keys.kNotificationTitle: title,
            GRNotification.Keys.kNotificationDescription: description,
            GRNotification.Keys.kDeviceId: deviceId,
            GRNotification.Keys.kCreationDate: Date().timeIntervalSince1970,
            GRNotification.Keys.kExpiration: expirationDate,
            GRNotification.Keys.kId: UUID().uuidString,
            GRNotification.Keys.kActive: false,
            GRNotification.Keys.kRemembered: false
        ]
        
        if let language = language {
            notificationData[GRNotification.Keys.kLanguage] = language
        }
        
        if let bookTitle = bookTitle {
            notificationData[GRNotification.Keys.kBookTitle] = bookTitle
        }
        
        if let tags = tags {
            notificationData[GRNotification.Keys.kTags] = tags            
        }
        
        // Create a notificatino object, this will be returned if save to server is successful
        var notification:GRNotification?
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: notificationData as Any, options: .prettyPrinted)
            notification = try JSONDecoder().decode(GRNotification.self, from: jsonData)
        } catch {
            print(error.localizedDescription)
        }
        
        guard let notificationId = notification?.id else
        {
            return .empty()
        }
        
        return Observable.create { (observer) -> Disposable in
            
            FirebasePersistenceManager.addDocument(
            withCollection: GRNotification.Keys.kCollectionName,
            data: notificationData,
            withId: notificationId) { (error, documents) in
                if let error = error {
                    observer.onError(error)
                    observer.onCompleted()
                } else if (documents != nil) {
                    observer.onNext(notification)
                    observer.onCompleted()
                }
                
                observer.onNext(nil)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    static func sync (_ id: String) {
                
        UtilityFunctions.updateDeviceId(id)
        
        if let fcmToken = FirebasePersistenceManager.shared.getFCMToken() {
            FirebasePersistenceManager.shared.saveFcmToken(fcmToken, forceSave: true)
        }
        
        self.getNotifications(deviceId: UtilityFunctions.deviceId()).subscribe { (event) in
            
            if let notifications = event.element {
                
                let updateDocuments = notifications.flatMap { [$0.id] }.flatMap { (notificationId) -> [String:[String:Any]] in
                    return [notificationId: [GRNotification.Keys.kDeviceId : id]]
                }.flatMap({ [$0.key: $0.value] })
                
                var updateDict = [String:[String:Any]]()
                
                updateDocuments.forEach { (key, value) in
                    updateDict[key] = value
                }
                                                
                return FirebasePersistenceManager.updateDocument(withId: nil, collection: GRNotification.Keys.kCollectionName, updateDoc: nil, documents:updateDict) { (error) in
                    
                }
                
            }
        }
        
    }
}
