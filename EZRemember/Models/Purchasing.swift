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
        
        static func getMessage (ruleName:String, rule: Int) -> String {
            switch ruleName {
            case Rules.kMaxNotificationCards:
                return "Sorry, but you can't have more than \(rule) active notification cards with your purchased package.  Please upgrade to complete this task."
            case Rules.kMaxLanguages:
                return "Sorry but you can't select more than \(rule) languages with your purchased package.  Please upgrade to complete this task."
            default:
                return "Sorry but you can't select more than \(rule) time slots with your purchased package.  Please upgrade to complete this task."
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
        
        PurchaseableItem(title: "Casual Learner", id: ProductIds.Basic.rawValue, info: "This service is good if you're casually learning something", price: 4.99, features: [
            "Translate text into 1 language",
            "Have a total of 5 notification cards at one time",
            "Recieve notifications up to 5 times a day"
        ], finePrint: "After your 7-day trial ends unless you unsubscribe you will be charged monthly"),
        
        // SERIOUS STUDENT
        
        PurchaseableItem(title: "Casual Student", id: ProductIds.Standard.rawValue, info: "This service is good if you're casually learning something", price: 3.99, features: [
            "Translate text into up to 3 languages",
            "Have a total of 15 notifications cards at one time",
            "Sync your data across multiple devices",
            "Recieve notifications up to 10 times a day"
        ], finePrint: "After your 7-day trial ends unless you unsubscribe you will be charged monthly"),
        
        // MASTER
        
        PurchaseableItem(title: "Serious Student", id: ProductIds.Premium.rawValue, info: "This service is good if you're casually learning something", price: 3.99, features: [
            "Translate text into up to 10 languages",
            "Have a total of 60 notifications cards at one time",
            "Recieve notifications up to 24 times a day"
        ], finePrint: "After your 7-day trial ends unless you unsubscribe you will be charged monthly")
    ]

    
}
