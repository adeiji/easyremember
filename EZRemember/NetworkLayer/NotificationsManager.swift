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
            
    /**
     Delete a notification with the given Id
     - parameter id: The unique id for this notification on Firebase.  **This is the documentId of the object on Firebase**
     
     - Todo: I need to remove the document query on deleteDocuments method
     - returns: An observable of type boolean, if true than that means the notification was deleted
     */
    static func deleteNotificationWithId (_ id: String) -> Observable<Bool> {
        return Observable.create { (observer) -> Disposable in
            FirebasePersistenceManager.deleteDocuments(withCollection: Notification.Keys.kCollectionName, documentId: id) { (success, error) in
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
    
    static func getNotifications (deviceId: String) -> Observable<[Notification]> {
        
        return Observable.create { (observer) -> Disposable in
            FirebasePersistenceManager.getDocuments(withCollection: Notification.Keys.kCollectionName, queryDocument: [
                Notification.Keys.kDeviceId: deviceId
            ], shouldKeepListening: true) { (error, documents) in
                if let error = error {
                    observer.onError(error)
                    observer.onCompleted()
                }
                
                if let documents = documents {
                    observer.onNext( FirebasePersistenceManager.getObjectsFromFirebaseDocuments(fromFirebaseDocuments: documents) as [Notification]? ?? [])
                }
            }
            
            return Disposables.create()
        }
    }
    
    static func saveNotification (title: String, description: String, deviceId:String) -> Observable<Notification?> {
        
        // 86400 is the amount of seconds in a day
        let expirationDate = Date().timeIntervalSince1970.advanced(by: 86400 * 7)
        let notificationData:[String:Any] = [
            Notification.Keys.kNotificationTitle: title,
            Notification.Keys.kNotificationDescription: description,
            Notification.Keys.kDeviceId: deviceId,
            Notification.Keys.kCreationDate: Date().timeIntervalSince1970,
            Notification.Keys.kExpiration: expirationDate,
            Notification.Keys.kId: UUID().uuidString
        ]
        
        // Create a notificatino object, this will be returned if save to server is successful
        var notification:Notification?
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: notificationData as Any, options: .prettyPrinted)
            notification = try JSONDecoder().decode(Notification.self, from: jsonData)
        } catch {
            print(error.localizedDescription)
        }
        
        guard let notificationId = notification?.id else { return .empty() }
        
        return Observable.create { (observer) -> Disposable in
            
            FirebasePersistenceManager.addDocument(
            withCollection: Notification.Keys.kCollectionName,
            data: notificationData,
            withId: notificationId) { (error, documents) in
                if let error = error {
                    observer.onError(error)
                    observer.onCompleted()
                    return
                } else if (documents != nil) {
                    observer.onNext(notification)
                    observer.onCompleted()
                    return
                }
                
                observer.onNext(nil)
            }
            
            return Disposables.create()
        }
    }    
}
