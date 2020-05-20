//
//  Sync.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/19/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation

struct Sync:Codable {
    
    struct Keys {
        
        static let kEmail = "email"
        static let kDeviceId = "deviceId"
        static let kBooks = "books"
        
    }
    
    let email:String
    let deviceId:String
    var books:[String]?
    
    static let collectionName = "sync"
    
}
