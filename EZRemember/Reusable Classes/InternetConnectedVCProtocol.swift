//
//  InternetConnectedVCProtocol.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 6/18/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit

protocol InternetConnectedVCProtocol: UIViewController {
    
    var internetNotConnectedDialogShown:Bool { get set }
    
}

extension InternetConnectedVCProtocol {
    internal func displayIfDeviceNotConnectedToInternet (_ message: String? = nil, _ superview: UIView? = nil) {
        if InternetConnectionManager.isConnectedToNetwork() == false && self.internetNotConnectedDialogShown == false {
            let messageCard = GRMessageCard()
            messageCard.layer.zPosition = 100
            messageCard.draw(message: message ?? "You can use this app without being connected to the internet, but you may experience strange behaviours within the app.  If possible, we recommend you connect your device to the internet.", title: "Device Not Connected to Internet", superview: superview ?? self.view, isError: true)
            self.internetNotConnectedDialogShown = true
            
            messageCard.firstButton?.addTargetClosure(closure: { [weak self] (_) in
                guard let self = self else { return }
                messageCard.close()
                self.internetNotConnectedDialogShown = false
            })
        }
    }
}
