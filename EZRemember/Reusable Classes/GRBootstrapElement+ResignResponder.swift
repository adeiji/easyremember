//
//  Style+ResignResponder.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/5/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import SwiftyBootstrap

extension GRBootstrapElement {
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        if touch?.phase == UITouch.Phase.began {
            self.endEditing(true)
        }
    }
    
}
