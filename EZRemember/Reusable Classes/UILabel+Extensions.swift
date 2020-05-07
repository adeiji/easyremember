//
//  UILabel+Extensions.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/5/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit

public extension UILabel {
    
    @discardableResult func font (_ font: UIFont) -> UILabel {
        self.font = font
        return self
    }
    
}
