//
//  UIButton+Image.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/1/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit

public extension UIButton {
    
    @discardableResult func withImage(named: String, bundle: String) -> UIButton {
        let image = ImageHelper.image(imageName: named, bundle: bundle)
        self.setImage(image, for: .normal)
        self.imageView?.contentMode = .scaleAspectFill
        return self
    }
    
}
