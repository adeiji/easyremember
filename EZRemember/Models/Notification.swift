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
        "en": NSLocalizedString("en", comment: "English"),
        "zh-TW": NSLocalizedString("zh-TW", comment: "Chinese (Traditional)"),
        "zh-CN": NSLocalizedString("zh-CN", comment: "Chinese (Simplified"),
        "id": NSLocalizedString("id", comment: "Indonesian"),
        "hi": NSLocalizedString("hi", comment: "Hindi"),
        "fr": NSLocalizedString("fr", comment: "French"),
        "es": NSLocalizedString("es", comment: "Spanish"),
        "pt": NSLocalizedString("pt", comment: "Portuguese"),
        "ar": NSLocalizedString("ar", comment: "Arabic"),
        "bn": NSLocalizedString("bn", comment: "Bengali"),
        "it": NSLocalizedString("it", comment: "Italian"),
        "ja": NSLocalizedString("ja", comment: "Japanese"),
        "tl": NSLocalizedString("tl", comment: "Tagolog"),
        "th": NSLocalizedString("th", comment: "Thai")
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
        static let kBookTitle = "bookTitle"
        static let kLanguage = "language"
        static let kTags = "tags"
        static let kRemembered = "remembered"
        static let kRememberedCount = "rememberedCount"
        static let kDeckId = "deckId"
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
    
    /// The book that this card came from if there is one
    var bookTitle:String?
    
    /// The tags for this card.  For example, maybe it's for "programming" or for "poetry" or something along those lines.  Currently on one tag is allowed, but we store as an array because we'll allow for more in the future
    var tags:[String]?
    
    /// Whether this card has been set to remembered for this user
    var remembered:Bool? = false
    
    var rememberedCount:Int? = 0
    
    /// If this notification was added from a deck than this value will be set
    var deckId:String?
    
    init(caption: String, description: String, language:String? = nil, tags:[String]? = nil, deckId:String? = nil) {
        self.id = UUID().uuidString
        self.caption = caption
        self.description = description
        self.deviceId = UtilityFunctions.deviceId()
        self.expiration = Date().addingTimeInterval(86400 * 7).timeIntervalSince1970
        self.creationDate = Date().timeIntervalSince1970
        self.active = false
        self.language = language
        self.deckId = deckId
    }
            
}
