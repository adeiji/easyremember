//
//  OnlinePurchase.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/30/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation

struct OnlinePurchase: Codable {
    
    static let kCollectionName = "online-purchase"
    
    let sessionId:String
    
    struct SubscriptionNicknames {
        static let basicMonthly = "Basic Monthly Easy Remember"
        static let standardMonthly = "Easy Remember Standard Package"
        static let premiumMonthly = "Easy Remember Premium Package Monthly"
        static let basicYearly = "Basic Package Yearly Easy Remember"
        static let standardYearly = "Easy Remember Standard Package Yearly"
        static let premiumYearly = "Easy Remember Premium Package Yearly"
    }
    
    func encode () -> [String:Any]? {
        guard let jsonData = try? JSONEncoder().encode(self) else { return nil }
        guard let dictionary = try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String: Any] else { return nil }
        
        return dictionary
    }
    
}
