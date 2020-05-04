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
    
    struct Keys {
        static let kCollectionName = "notifications"
        static let kNotificationTitle = "title"
        static let kNotificationDescription = "description"
        static let kDeviceId = "deviceId"
    }
    
    static func saveNotification (title: String, description: String, deviceId:String) -> Observable<Bool> {
        
        return Observable.create { (observer) -> Disposable in
            FirebasePersistenceManager.addDocument(withCollection: Keys.kCollectionName, data: [
                Keys.kNotificationTitle: title,
                Keys.kNotificationDescription: description,
                Keys.kDeviceId: deviceId
            ]) { (error, documents) in
                if let error = error {
                    observer.onError(error)
                    observer.onCompleted()
                    return
                } else if (documents != nil) {
                    observer.onNext(true)
                    observer.onCompleted()
                    return
                }
                
                observer.onNext(false)
            }
            
            return Disposables.create()
        }
    }    
}
