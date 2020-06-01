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
    
    let email:String
    
    let purchaseId:String
    
    let package:String
    
    func encode () -> [String:Any]? {
        guard let jsonData = try? JSONEncoder().encode(self) else { return nil }
        guard let dictionary = try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String: Any] else { return nil }
        
        return dictionary
    }
    
}
