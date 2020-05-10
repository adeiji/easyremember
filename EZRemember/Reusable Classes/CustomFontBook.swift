//
//  CustomFontBook.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/5/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import SwiftyBootstrap

public enum CustomFontBook:String {
//    case logo = "Gill Sans"
    case ExtraLight = "Poppins-ExtraLight"
    case ThinItalic = "Poppins-ThinItalic"
    case ExtraLightItalic = "Poppins-ExtraLightItalic"
    case BoldItalic = "Poppins-BoldItalic"
    case Light = "Poppins-Light"
    case Medium = "Poppins-Medium"
    case SemiBoldItalic = "Poppins-SemiBoldItalic"
    case ExtraBoldItalic = "Poppins-ExtraBoldItalic"
    case ExtraBold = "Poppins-ExtraBold"
    case BlackItalic = "Poppins-BlackItalic"
    case Regular = "Poppins-Regular"
    case LightItalic = "Poppins-LightItalic"
    case Bold = "Poppins-Bold"
    case Black = "Poppins-Black"
    case Thin = "Poppins-Thin"
    case SemiBold = "Poppins-SemiBold"
    case Italic = "Poppins-Italic"
    case MediumItalic = "Poppins-MediumItalic"
    
    public func forSizeClass() -> UIFont {
        let sizeClass = GRCurrentDevice.shared.size
        
        switch sizeClass {
        case .xs:
            return self.of(size: .verySmall)
        case .sm:
            return self.of(size: .medium)
        case .md:
            return self.of(size: .medium)
        case .lg:
            return self.of(size: .medium)
        default:
            return self.of(size: .large)
        }
    }
    
    public func of(size: FontSizes) -> UIFont {
        return UIFont(name: self.rawValue, size: size.rawValue) ?? UIFont.systemFont(ofSize: size.rawValue)
    }
    
}
