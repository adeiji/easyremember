//
//  Purchasing.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/18/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation

struct Purchasing {
    
    struct Rules {
        
        static let kMaxNotificationCards = "maxNotificationCards"
        static let kMaxLanguages = "maxLanguages"
        static let kMaxTimes = "maxTimes"
        static let kRequiresPurchase = "requiresPurchase"
        
        struct Free {
            static let rules = [
                Rules.kMaxNotificationCards : 3,
                Rules.kMaxLanguages: 1,
                Rules.kMaxTimes: 5
            ]
        }
        
        struct Basic {
            static let rules = [
                Rules.kMaxNotificationCards : 10,
                Rules.kMaxLanguages: 3,
                Rules.kMaxTimes: 10
            ]
        }
        
        struct Standard {
            static let rules = [
                kMaxNotificationCards : 20,
                kMaxLanguages: 5,
                kMaxTimes: 10
            ]
        }
        
        struct Premium {
            static let rules = [
                kMaxNotificationCards : 64,
                kMaxLanguages: 0,
                kMaxTimes: 0
            ]
        }
        
        static func getMessage (ruleName:String, rule: Int? = nil) -> String {
            
            guard let rule = rule else {
                return "Sorry, but you must subscribe to one of our packages to perform this task."
            }
            
            switch ruleName {
            case Rules.kMaxNotificationCards:
                return "Sorry, but you can't have more than \(rule) active notification cards with your purchased package.  Please upgrade to complete this task."
            case Rules.kMaxLanguages:
                return "Sorry but you can't select more than \(rule) languages with your purchased package.  Please upgrade to complete this task."
            case Rules.kMaxTimes:
                return "Sorry but you can't select more than \(rule) time slots with your purchased package.  Please upgrade to complete this task."
            default:
                return "Sorry, but your current subscription only allows \(rule) of this task.  Please upgrade to complete this task."
            }
        }
    }
    
    enum ProductIds:String {
        case Basic = "ezremember.basic"
        case Standard = "ezremember.standard"
        case Premium = "ezremember.premium"
        
    }
    
    static let inAppPurchaseProductIds:[String] = [
        ProductIds.Basic.rawValue,
        ProductIds.Standard.rawValue,
        ProductIds.Premium.rawValue
    ]

    static let purchaseItems = [
        
        // CASUAL LEARNER PACKAGE
        
        PurchaseableItem(title: NSLocalizedString("basicPackageTitle", comment: "The title for purchasing package casual learner"), id: ProductIds.Basic.rawValue, info: NSLocalizedString("basicPackageDescription", comment: "An overview of this package"), price: 4.99, features: [
            NSLocalizedString("basicPackageTranslation", comment: "What you receive with this package with regards to language translation"),
            NSLocalizedString("basicPackageMaxNotifications", comment: "What you receive with this package with regards to max notifications"),
            NSLocalizedString("basicPackageMaxHourSlots", comment: "What you receive with this package with regards to hour slots")
        ], finePrint: NSLocalizedString("purchasingFinePrint", comment: "The fine print for this package")),
        
        // SERIOUS STUDENT
        
        PurchaseableItem(title: NSLocalizedString("standardPackageTitle", comment: "The title for this package"), id: ProductIds.Standard.rawValue, info: NSLocalizedString("standardPackageDescription", comment: "An overview of this package"), price: 4.99, features: [
            NSLocalizedString("standardPackageSpeed", comment: "What you receive with this package with regards to speed of learning"),
            NSLocalizedString("standardPackageTranslation", comment: "What you receive with this package with regards to language translation"),
            NSLocalizedString("standardPackageMaxNotifications", comment: "What you receive with this package with regards to max notifications"),
            NSLocalizedString("standardPackageMaxHourSlots", comment: "What you receive with this package with regards to hour slots")
        ], finePrint: NSLocalizedString("purchasingFinePrint", comment: "The fine print for this package")),
        
        // MASTER
        
        PurchaseableItem(title: NSLocalizedString("premiumPackageTitle", comment: "The title for this package"), id: ProductIds.Standard.rawValue, info: NSLocalizedString("premiumPackageDescription", comment: "An overview of this package"), price: 4.99, features: [
            NSLocalizedString("premiumPackageSpeed", comment: "What you receive with this package with regards to speed of learning"),
            NSLocalizedString("premiumPackageTranslation", comment: "What you receive with this package with regards to language translation"),
            NSLocalizedString("premiumPackageMaxNotifications", comment: "What you receive with this package with regards to max notifications"),
            NSLocalizedString("premiumPackageMaxHourSlots", comment: "What you receive with this package with regards to hour slots")
        ], finePrint: NSLocalizedString("purchasingFinePrint", comment: "The fine print for this package"))
    ]

    
}
