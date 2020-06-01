//
//  Sentence.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/31/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation

struct Sentence: Codable {
    
    static let kCollectionName = "sentences"
    
    let sentence: String
    
    let creationDate: TimeInterval
    
    let deviceId: String
    
    let id: String
    
    func encode () -> [String:Any]? {
        guard let jsonData = try? JSONEncoder().encode(self) else { return nil }
        guard let dictionary = try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String: Any] else { return nil }
        
        return dictionary
    }


    
}

