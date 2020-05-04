//
//  UIVIew+Shadow.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/1/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    public func backgroundColor (_ color: UIColor) -> UIView {
        self.backgroundColor = color
        return self
    }
    
    /**
     Add shadow to a view, make sure that the background color is not set to clear
     */
    @discardableResult public func addShadow () -> UIView {
                                
        self.clipsToBounds = false
        self.layer.shadowColor = UIColor.gray.cgColor
        self.layer.shadowOpacity = 0.3
        self.layer.shadowOffset = CGSize(width: 1, height: 5)
        self.layer.shadowRadius = 3
        self.layer.shouldRasterize = true
        
        return self
        
    }
    
    /**
     Set the radius for a view
     */
    @discardableResult public func radius (radius: CGFloat) -> UIView {
        self.layer.cornerRadius = radius
        return self
    }            
}
