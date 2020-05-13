//
//  Notification.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/6/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation

/**
 
 Notifications are the premise of this entire application.  Push Notifications will be sent to the user based off of the information that is stored here.  Notifications will not automatically change, the user will have to set the notifications that he wants shown at the time
 
 - Note:
 **Future plan**
 The expiration date is initially set to one week ahead of the day that it was created but we won't use that for the time being.
 Once that expiration date is reached, if it's set to active, it's set to inactive and then another item should
 be selected from the list of notifications
 
 */
struct GRNotification: Codable {
    
    public static let kSavedNotifications = "savedNotifications"
    public static let kSupportedLanguages = [
        "en": "English",
        "zh-TW": "Chinese (Traditional)",
        "zh-CN": "Chinese (Simplified)",
        "id": "Indonesian",
        "hi": "Hindi",
        "fr": "French",
        "es": "Spanish",
        "pt": "Portuguese"
    ]
    
    /** Given a value, return the shortcode for that value */
    public static func getLanguageShortCodeForValue (_ value: String) -> String? {
        
        for key in GRNotification.kSupportedLanguages.keys {
            if GRNotification.kSupportedLanguages[key] == value {
                return key
            }
        }
                        
        return nil
    }
    
    struct Keys {
        static let kCollectionName = "notifications"
        static let kNotificationTitle = "caption"
        static let kNotificationDescription = "description"
        static let kExpiration = "expiration"
        static let kCreationDate = "creationDate"
        static let kDeviceId = "deviceId"
        static let kId = "id"
        static let kActive = "active"
    }
    
    /// The id of the Notification to access it
    let id:String
    
    /// The proverbial front side of a flash card, the word or info that you want to remember
    var caption:String
    
    /// The description, kind of like the back side of a flash card, this is the actual content of the card
    var description:String
    
    /// The Id of the device that this notification is for
    var deviceId:String
    
    /// When the notification should stop showing automatically. Stored as Time Interval since 1970
    let expiration:Double
    
    ///The date of creation for the notification.  Stored as Time Interval since 1970
    let creationDate:Double
    
    /// Whether or not this notification is set to be sent
    var active:Bool
    
    /// The language that this notification is in. This is only set when recieving a translation from the server
    var language:String?
            
}
