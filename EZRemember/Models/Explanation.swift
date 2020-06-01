//
//  Explanation.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/21/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit

struct Explanation {
    
    let sections:[ExplanationSection]
        
}

struct ExplanationSection {
    
    let content:String
    let title:String
    let id:String = UUID().uuidString
    let image:UIImage?
    var largeImage:Bool = false
    
}
