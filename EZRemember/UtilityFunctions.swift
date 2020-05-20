//
//  UtilityFunctions.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/5/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit

class UtilityFunctions {
    
    static let kDeviceId = "deviceId"
    static let kSyncIds = "syncIds"
    static let kTags = "tags"
    static let kSyncEmail = "syncEmail"
    
    /**
     Get the deviceId for this user's device and if it doesn't exist, than create it.  Obviously this will change
     if the user ever deletes the app and reinstalls it since the deviceId is stored in user defaults
     */
    static func deviceId () -> String {
        
        // Grab the device Id
        let userDefaults = UserDefaults()
        var deviceId = userDefaults.object(forKey: UtilityFunctions.kDeviceId) as? String
        
        if (deviceId == nil) {
            deviceId = UUID().uuidString.lowercased()
            userDefaults.set(deviceId, forKey: UtilityFunctions.kDeviceId)
        }
        
        return deviceId!
    }
    
    static func updateDeviceId (_ deviceId: String) {
        // Grab the device Id
        let userDefaults = UserDefaults()
        userDefaults.set(deviceId, forKey: UtilityFunctions.kDeviceId)
        userDefaults.synchronize()
    }
    
    static func addSyncId (_ syncId: String) {
        // Grab the device Id
        let userDefaults = UserDefaults()
        var syncIds:[String] = userDefaults.value(forKey: UtilityFunctions.kSyncIds) as? [String] ?? []
        
        // Don't store duplicates
        if syncId.contains(syncId.lowercased()) {
            return
        }
        
        syncIds.append(syncId.lowercased())
        userDefaults.set(syncIds, forKey: UtilityFunctions.kSyncIds)
        userDefaults.synchronize()
    }
    
    static func syncIds () -> [String]? {
        let userDefaults = UserDefaults()
        let syncIds = userDefaults.value(forKey: UtilityFunctions.kSyncIds) as? [String] ?? []
        return syncIds
    }
    
    static func addTags (newTags: [String]) {
        guard let tag = newTags.first else { return }
        
        // Add the tag
        let userDefaults = UserDefaults()
        var tags:[String] = userDefaults.value(forKey: UtilityFunctions.kTags) as? [String] ?? []
        if tags.contains(tag) { return }
        tags.append(contentsOf: newTags)
        userDefaults.set(tags, forKey: UtilityFunctions.kTags)
        userDefaults.synchronize()
    }
    
    static func getTags () -> [String]? {
        let userDefaults = UserDefaults()
        let tags = userDefaults.value(forKey: UtilityFunctions.kTags) as? [String]
        return tags
    }
    
    static func urlIsEpub (url: URL) -> Bool {
        guard let positionOfLastPeriod = url.absoluteString.lastIndex(of: ".") else { return false }
        let fileType = url.absoluteString.suffix(from: positionOfLastPeriod)
        if fileType.lowercased() == ".epub" { return true }
        
        return false
    }
    
    static func getNextHour () -> Int {
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        if hour == 24 {
            return 0
        }
        
        return hour + 1
    }
    
    static func addSyncEmail (_ email: String) {
        // Grab the device Id
        let userDefaults = UserDefaults()
        userDefaults.setValue(email, forKey: UtilityFunctions.kSyncEmail)
        userDefaults.synchronize()        
    }
    
    static func getSyncEmail () -> String?
    {
        let userDefaults = UserDefaults()
        return userDefaults.object(forKey: UtilityFunctions.kSyncEmail) as? String
    }
    
}
