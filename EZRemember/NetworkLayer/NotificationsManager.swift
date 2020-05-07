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

class NotificationsManager {
        
    let disposeBag = DisposeBag()
    
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
    
    /**
     Get all the notifications for this device
     
     - parameter deviceId: The Unique Id for this device, you can retrieve it using UtilityFunctions.deviceId()
     */
    static func getNotifications (deviceId: String) -> Observable<[GRNotification]> {
        
        return Observable.create { (observer) -> Disposable in
            FirebasePersistenceManager.getDocuments(withCollection: GRNotification.Keys.kCollectionName, queryDocument: [
                GRNotification.Keys.kDeviceId: deviceId
            ], shouldKeepListening: true) { (error, documents) in
                if let error = error {
                    observer.onError(error)
                    observer.onCompleted()
                }
                
                if let documents = documents {
                    observer.onNext( FirebasePersistenceManager.getObjectsFromFirebaseDocuments(fromFirebaseDocuments: documents) as [GRNotification]? ?? [])
                }
            }
            
            return Disposables.create()
        }
    }
    
    /**
     Toggle this notification as active or inactive
     
     - parameters:
        - notificationId: The id for this notification, it should be the document Id for the notification in the Notification collection
        - active: The active state of this notification, this needs to be the state that you want to be saved on the server.  So if you want this to now be an active notification you need to set **active** to **true**
     */
    static func toggleActiveNotification (notificationId: String, active: Bool) -> Observable<Bool> {
        
        return Observable.create { (observer) -> Disposable in
            
            FirebasePersistenceManager.updateDocument(withId: notificationId, collection: GRNotification.Keys.kCollectionName, updateDoc: [
                GRNotification.Keys.kActive: active
            ]) { (error) in
                if let error = error {
                    observer.onError(error)
                    observer.onCompleted()
                    return
                }
                
                // Successful
                observer.onNext(true)
            }
            
            return Disposables.create()
        }
    }
    
    func saveNotifications (_ notifications: [GRNotification], completed: @escaping (Bool) -> Void ) {
        var observables = [Observable<GRNotification?>]()
        
        notifications.forEach { [weak self] (notification) in
            guard let self = self else { return }
            
            observables.append(self.saveNotification(title: notification.caption, description: notification.description, deviceId: notification.deviceId))
        }
                        
        Observable.merge(observables).takeLast(1).subscribe { [weak self] (event) in
            guard let _ = self else { return }
            completed(true)
        }.disposed(by: self.disposeBag)
    }
    
    func saveNotification (title: String, description: String, deviceId:String) -> Observable<GRNotification?> {
        
        // 86400 is the amount of seconds in a day
        let expirationDate = Date().timeIntervalSince1970.advanced(by: 86400 * 7)
        let notificationData:[String:Any] = [
            GRNotification.Keys.kNotificationTitle: title,
            GRNotification.Keys.kNotificationDescription: description,
            GRNotification.Keys.kDeviceId: deviceId,
            GRNotification.Keys.kCreationDate: Date().timeIntervalSince1970,
            GRNotification.Keys.kExpiration: expirationDate,
            GRNotification.Keys.kId: UUID().uuidString,
            GRNotification.Keys.kActive: false
        ]
        
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
}
