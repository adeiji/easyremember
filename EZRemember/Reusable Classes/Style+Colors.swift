//
//  Style+Colors.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/5/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import SwiftyBootstrap

public extension UIColor {
    
    struct DarkMode {
        public static var mediumShadeGray:UIColor { return UIColor(red: 59/255, green: 67/255, blue: 75/255, alpha: 1.0) }
        public static var brownishTan:UIColor { return UIColor(red: 234/255, green: 185/255, blue: 140/255, alpha: 1.0) }
        public static var blueNeonGreen:UIColor { return UIColor(red: 27/255, green: 218/255, blue: 192/255, alpha: 1.0) }
        public static var epubReaderBlack:UIColor { return UIColor(red: 19/255, green: 20/255, blue: 20/255, alpha: 1.0) }
        public static var coolGrey50:UIColor { return UIColor(hexString: "F5F7FA" ) }
        public static var coolGrey200:UIColor { return UIColor(hexString: "CBD2D9" ) }
        public static var coolGrey700:UIColor { return UIColor(hexString: "3E4C59" ) }
        public static var coolGrey900:UIColor { return UIColor(hexString: "1F2933") }
        
    }
    
    struct EZRemember {
        public static var mainBlue: UIColor { return  UIColor(red: 48/255, green: 105/255, blue: 199/255, alpha: 1.0) }
        public static var veryLightGray: UIColor { return UIColor(red: 246/255, green: 248/255, blue: 252/255, alpha: 1.0) }
        public static var lightGreen: UIColor { return UIColor(red: 237/255, green: 255/255, blue: 233/255, alpha: 1.0) }
        public static var lightRed: UIColor { return UIColor(red: 255/255, green: 233/255, blue: 233/255, alpha: 1.0) }
        public static var lightGreenButtonText: UIColor { return UIColor(red: 72/255, green: 182/255, blue: 19/255, alpha: 1.0) }
        public static var lightRedButtonText: UIColor { return UIColor(red: 255/255, green: 74/255, blue: 74/255, alpha: 1.0) }
    }
    
}

public typealias Dark = UIColor.DarkMode
