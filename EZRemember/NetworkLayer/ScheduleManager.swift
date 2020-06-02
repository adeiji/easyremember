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
        static let kLanguages = "languages"
        static let kFrequency = "frequency"
        static let kStyle = "style"
        static let kSentence = "sentence"
        static let kPurchasedPackage = "purchasedPackage"
    }
    
    struct NotificationsType {
        static let kFlashcardContentVisible = "Flashcard - Hide Content"
        static let kFlashcardCaptionVisible = "Flashcard - Hide Caption"
        static let kShowEverything = "Show Everything"
    }
    
    struct PurchaseTypes {
        static let kBasic = "basic"
        static let kStandard = "standard"
        static let kPremium = "premium"
        static let kTest = "test"
    }
            
    let deviceId:String
    var timeSlots:[Int]
    let maxNumOfCards:Int
    let languages:[String]
    var frequency:Int = 60
    
    var purchasedPackage:String?
    
    var sentence:String?
    
    /// The type of notification to be shown, is it Flashcard Style with only the caption showing and then needing to click to show the content
    /// or Flashcard Style with content showing
    /// or Show Everything
    var style:String?
    
    /**
     Convert all the time slots to their UTC equivalent
     
    - parameter to: Converting to or from UTC
     */
    mutating func convertTimeSlotsUTC (to: Bool) {
        var timeSlotsCopy = self.timeSlots
        for index in 0..<self.timeSlots.count {
            let time = self.timeSlots[index]
            
            var timeDifference = (TimeZone.current.secondsFromGMT() / 60 / 60)
            if (to) {
                timeDifference = timeDifference * -1
            }
            
            timeSlotsCopy[index] = self.addHoursToHour(time, timeDifference)
        }
        
        self.timeSlots = timeSlotsCopy
    }
    
    private func addHoursToHour (_ hour: Int, _ hoursToAdd: Int) -> Int {
        var newHour = hour + hoursToAdd
        if newHour >= 24 {
            newHour = newHour - 24
        } else if newHour < 0 {
            newHour = 24 + newHour
        }
        
        return newHour
    }
    
    func encode () -> [String:Any]? {
        guard let jsonData = try? JSONEncoder().encode(self) else { return nil }
        guard let dictionary = try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String: Any] else { return nil }
        
        return dictionary
    }
    
}

/**
 
 Every hour we will check to see which people have their notification time slot set to that hour.  For all those who have it set
 we will send them a notification.  The user will have to select which items he wants sent, or if he wants things to change automatically.
 If a notification is not to be sent at that time, then it will be set to inactive.
 
 */

class ScheduleManager {
    
    private var languages:[String] = ["en"]
    
    static let shared = ScheduleManager()
    
    private let disposeBag = DisposeBag()
    
    private var schedule:Schedule?
    
    private init () {
        NotificationCenter.default.addObserver(self, selector: #selector(updateLanguages(_:)), name: .LanguagesUpdated, object: nil)
    }
    
    @objc private func updateLanguages (_ notification:Notification) {
        guard let languages = notification.userInfo?["languages"] as? [String] else { return }
        self.languages = languages
    }
    
    public func getLanguages () -> [String] {
        return self.languages
    }
    
    public func getSchedule () -> Schedule? {
        return self.schedule
    }
    
    private func setSchedule (_ schedule:Schedule) {
        self.schedule = schedule
    }
    
    public func getSubscriptionForSessionId (_ sessionId: String) -> Observable<String?> {
        guard let url = URL(string: "https://graffitisocial.herokuapp.com/sessionSubscription?sessionId=\(sessionId)") else { return .empty() }
        let request = URLRequest(url: url)
        
        return Observable.create { (observer) -> Disposable in
        
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    observer.onError(error)
                    observer.onCompleted()
                    return
                }
                
                guard let data = data else {
                    observer.onNext(nil)
                    observer.onCompleted()
                    return
                }
                
                guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else { return }
                if let object = json as? [String:Any] {
                    let packageName = self.getPackageFromSubscriptionNickname(object["name"] as? String)
                    observer.onNext(packageName)
                    observer.onCompleted()
                }
            }
            
            task.resume()
            
            return Disposables.create()
        }
    }
    
    private func getPackageFromSubscriptionNickname (_ nickName:String?) -> String? {
        guard let nickName = nickName?.lowercased() else { return nil }
        if (nickName.contains(Schedule.PurchaseTypes.kBasic)) { return Schedule.PurchaseTypes.kBasic }
        else if (nickName.contains(Schedule.PurchaseTypes.kStandard)) { return Schedule.PurchaseTypes.kStandard }
        else if (nickName.contains(Schedule.PurchaseTypes.kPremium)) { return Schedule.PurchaseTypes.kPremium }
        else if (nickName.contains(Schedule.PurchaseTypes.kTest)) { return Schedule.PurchaseTypes.kPremium }
        
        return nil
    }
    
    public func getPurchaseWithId (_ purchaseId: String, completion: @escaping (OnlinePurchase?, Error?) -> Void) {
        FirebasePersistenceManager.getDocumentById(forCollection: OnlinePurchase.kCollectionName, id: purchaseId).subscribe({ [weak self] (event) in
            guard let _ = self else { return }
            
            if let error = event.error {
                completion(nil, error)
            } else if let document = event.element {
                let onlinePurchase = FirebasePersistenceManager.generateObject(fromFirebaseDocument: document) as OnlinePurchase?
                completion(onlinePurchase, nil)
            } else if event.isCompleted == false {
                completion(nil, nil)
            }
                        
        }).disposed(by: self.disposeBag)
    }
    
    public func setPurchasePackage (_ package: String, completion: @escaping (Bool, Error?) -> Void) {
        FirebasePersistenceManager.updateDocument(withId: UtilityFunctions.deviceId(), collection: Schedule.Keys.kCollectionName, updateDoc: [ Schedule.Keys.kPurchasedPackage: package ]) { (error) in
            completion(error == nil, error)
            self.schedule?.purchasedPackage = package
        }
    }
    
    /**
     Save the schedule for this device to the server.  Notifications will be sent to this device based off of
     the time slots that they chose
     
     - parameter timeSlots: The times that this user wants to recieve notifications.
     */
    func saveSchedule (_ mySchedule: Schedule) -> Observable<Bool> {
        
        let deviceId = UtilityFunctions.deviceId()
        var schedule = mySchedule
        schedule.convertTimeSlotsUTC(to: true)
        
        guard let documentToSave = schedule.encode() else {
            assertionFailure("Baaka, why is it that the Schedule object is not encodable")
            return .empty()
        }
        
        self.setSchedule(schedule)
        
        return Observable.create { (observer) -> Disposable in                                    
            FirebasePersistenceManager.addDocument(withCollection: Schedule.Keys.kCollectionName, data: documentToSave, withId: deviceId) { (error, documents) in
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
    
    func saveSentence (_ sentence: String) {
        
        let deviceId = UtilityFunctions.deviceId()
        FirebasePersistenceManager.updateDocument(withId: deviceId, collection: Schedule.Keys.kCollectionName, updateDoc: [Schedule.Keys.kSentence: sentence], completion: nil)
        let sentenceId = UUID().uuidString
        let sentence = Sentence(sentence: sentence, creationDate: Date().timeIntervalSince1970, deviceId: deviceId, id: sentenceId)
        
        // Save the sentence for future usage
        guard let sentenceDict = sentence.encode() else { return }
        FirebasePersistenceManager.addDocument(withCollection: Sentence.kCollectionName, data: sentenceDict, withId: sentenceId, completion: nil)
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
    func getScheduleFromServer () -> Observable<Schedule?> {
        let deviceId = UtilityFunctions.deviceId()
                        
        let getSchedule = FirebasePersistenceManager.getDocumentById(forCollection: Schedule.Keys.kCollectionName, id: deviceId)
        .map({  FirebasePersistenceManager.generateObject(fromFirebaseDocument: $0) as Schedule? })
        
        getSchedule.subscribe { [weak self] (event) in
            guard let self = self else { return }
            if let settings = event.element, let languages = settings?.languages {
                self.languages = languages
                if let settings = settings { self.setSchedule(settings) }
            }
        }.disposed(by: self.disposeBag)
        
        return getSchedule
    }
    
}
