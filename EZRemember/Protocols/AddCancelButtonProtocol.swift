//
//  AddCancelButtonProtocol.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/19/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import SwiftyBootstrap

protocol AddCancelButtonProtocol: UIViewController {
        
}

extension AddCancelButtonProtocol {
    
    func addCancelButton (navBar:GRNavBar?, white:Bool = false) {
                        
        if UIScreen.main.traitCollection.userInterfaceStyle == .dark || white {
            navBar?.leftButton?.setImage(ImageHelper.image(imageName: "close-button", bundle: "SwiftyBootstrap"), for: .normal)
        } else {
            navBar?.leftButton?.setImage(ImageHelper.image(imageName: "cancel-black", bundle: "SwiftyBootstrap"), for: .normal)
        }
        
        navBar?.leftButton?.showsTouchWhenHighlighted = true
        navBar?.backgroundColor = .clear
        navBar?.leftButton?.imageEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: -10)
        
        navBar?.leftButton?.addTargetClosure(closure: { [weak self] (_) in
            guard let self = self else { return }
            self.dismiss(animated: true, completion: nil)
        })
        
    }
    
}
