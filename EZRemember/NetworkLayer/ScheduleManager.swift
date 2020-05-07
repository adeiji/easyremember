//
//  ScheduleManager.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/5/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import DephynedFire
import RxSwift

struct Schedule: Codable {
    
    struct Keys {
        static let kCollectionName = "schedule"
        static let kDeviceId = "deviceId"
        static let kTimeSlots = "timeSlots"
        static let kMaxNumOfCards = "maxNumOfCards"
        static let kFcmToken = "fcmToken"
    }
    
    let deviceId:String
    let timeSlots:[Int]
    let maxNumOfCards:Int
    let fcmToken:String?
    
}

/**
 
 Every hour we will check to see which people have their notification time slot set to that hour.  For all those who have it set
 we will send them a notification.  The user will have to select which items he wants sent, or if he wants things to change automatically.
 If a notification is not to be sent at that time, then it will be set to inactive.
 
 */

class ScheduleManager {
    
    /**
     Save the schedule for this device to the server.  Notifications will be sent to this device based off of
     the time slots that they chose
     
     - parameter timeSlots: The times that this user wants to recieve notifications.
     */
    static func saveSchedule (timeSlots:[Int], maxNumOfCards:Int) -> Observable<Bool> {
        
        let delegate = UIApplication.shared.delegate as? AppDelegate
        guard let deviceId = delegate?.deviceId else { return .just(false) }
        
        return Observable.create { (observer) -> Disposable in
            
            FirebasePersistenceManager.addDocument(withCollection: Schedule.Keys.kCollectionName, data: [
                Schedule.Keys.kDeviceId: deviceId,
                Schedule.Keys.kTimeSlots: timeSlots,
                Schedule.Keys.kMaxNumOfCards: maxNumOfCards
            ], withId: deviceId) { (error, documents) in
                if let error = error {
                    observer.onError(error)
                    observer.onCompleted()
                } else {
                    observer.onNext(true)
                    observer.onCompleted()
                }
            }
            
            return Disposables.create()
        }
    }
    
    /**
     Get the max number of cards that will be sent as notifications from the server
     
     - returns: An observable of the max number, defaults to 5 if the user has not saved this to the server yet
     */
    static func getMaxNumOfCards () -> Observable<Int> {
        
        let deviceId = UtilityFunctions.deviceId()
                
        // Get the schedule with this device's id
        return FirebasePersistenceManager.getDocumentById(forCollection: Schedule.Keys.kCollectionName, id: deviceId)
            .map( { (FirebasePersistenceManager.generateObject(fromFirebaseDocument: $0) as Schedule?)?.maxNumOfCards ?? 5 } )
    }
    
    /**
     Get the times that the user has selected to have notifications sent to them
     - returns: An observable containing the times
     */
    static func getSchedule () -> Observable<Schedule?> {
        let deviceId = UtilityFunctions.deviceId()
        
        return FirebasePersistenceManager.getDocumentById(forCollection: Schedule.Keys.kCollectionName, id: deviceId)
            .map({  FirebasePersistenceManager.generateObject(fromFirebaseDocument: $0) as Schedule? })
    }
}
