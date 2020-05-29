//
//  DeckNotification.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/29/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation

struct DeckNotification: Codable {
    
    struct Keys {
        static let kCollectionName = "deck-notifications"
        static let deckId = "deckId"
    }
    
    let caption:String
    
    let deckId:String
    
    let description:String
    
    let id:String
    
    let language:String?
    
    let tags:String
    
}
