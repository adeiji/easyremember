//
//  Deck.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/29/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation


struct Deck: Codable {
    
    struct Keys {
        static let kCollectionName = "decks"
    }
    
    let cardCount:Int
    
    let id:String
    
    let name:String
    
    let description:String
    
}
