//
//  ToastHandler.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/25/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import SwiftyBootstrap

class ToastHandler {
    
    var tappedHandler: (() -> Void)?
    
    private var toastCard:GRBootstrapElement?
    
    init(completionHandler: (() -> Void)? = nil) {
        self.tappedHandler = completionHandler
    }
    
    func showToast (_ text: String, timelimit: TimeInterval? = nil, superview: UIView? = nil) {
                            
        let card = GRBootstrapElement(color: UIColor.EZRemember.mainBlue.dark(Dark.brownishTan), anchorWidthToScreenWidth: true, margin: BootstrapMargin.noMargins(), superview: nil)
        
        card.addRow(columns: [
            Column(cardSet: Style.label(withText: text, superview: nil, color: UIColor.white.dark(Dark.coolGrey900))
                .toCardSet()
                .margin.left(40)
                .margin.right(40)
                .margin.top(0)
                .margin.bottom(0),
                   xsColWidth: .Twelve)
        ], anchorToBottom: true)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(toastTapped))
        card.addGestureRecognizer(tapRecognizer)
        
        guard let window = UIApplication.shared.windows.first else { return }
        
        card.layer.zPosition = 100
        
        card.slideUp(superview: superview ?? window, margin: 0, width: nil)
        self.toastCard = card
    }
    
    @objc private func toastTapped () {
        if let completion = self.tappedHandler {
            self.hideToast()
            completion()
        }
    }
    
    func hideToast () {
        guard let superview = self.toastCard?.superview else { return }
        self.toastCard?.slideDownAndRemove(superview: superview)
    }
    
}
