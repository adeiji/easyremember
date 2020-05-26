//
//  DEImageHelper.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/1/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import SwiftyBootstrap
import PodAsset

public struct ImageHelper {
            
    public static func image(imageName: String, bundle:String = "SwiftyBootstrap") -> UIImage? {
        let bundle = PodAsset.bundle(forPod: bundle)
        if #available(iOS 13.0, *) {
            let img = UIImage(named: imageName, in: bundle, compatibleWith: .current)
            return img
        } else {
            // Fallback on earlier versions
            let img = UIImage(named: imageName, in: bundle, compatibleWith: .none)
            return img
        }        
    }
}
