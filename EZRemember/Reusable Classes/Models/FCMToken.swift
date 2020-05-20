//
//  FCMToken.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/20/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation

struct FCMToken:Codable {
    
    static let collectionName = "fcmTokens"
    
    let deviceId:String
    var token:String
    
}
