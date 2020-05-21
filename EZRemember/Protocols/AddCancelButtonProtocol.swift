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
    
    func addCancelButton (view: GRViewWithScrollView) {
        
        if UIScreen.main.traitCollection.userInterfaceStyle == .dark {
            view.navBar?.leftButton?.setImage(ImageHelper.image(imageName: "close-button", bundle: "SwiftyBootstrap"), for: .normal)
        } else {
            view.navBar?.leftButton?.setImage(ImageHelper.image(imageName: "close-black", bundle: "SwiftyBootstrap"), for: .normal)
        }
        
        view.navBar?.leftButton?.showsTouchWhenHighlighted = true
        view.navBar?.backgroundColor = .clear
        view.navBar?.leftButton?.imageEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: -10)
        
        view.navBar?.leftButton?.addTargetClosure(closure: { [weak self] (_) in
            guard let self = self else { return }
            self.dismiss(animated: true, completion: nil)
        })
        
    }
    
}
