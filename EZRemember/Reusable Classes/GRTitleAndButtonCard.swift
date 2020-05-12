//
//  GRTitleAndButtonCard.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/12/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import SwiftyBootstrap

class GRTitleAndButtonCard: GRBootstrapElement {
    
    weak var actionButton:UIButton?
    
    func draw (title: String, buttonTitle:String) {
        
        let actionButton = Style.largeButton(with: buttonTitle, backgroundColor: UIColor.EZRemember.mainBlue.dark(Dark.blueNeonGreen))
        actionButton.titleLabel?.font = CustomFontBook.Bold.of(size: .small)
        
        self.addRow(columns: [
            // Would the user like to sync?
            Column(cardSet: Style.label(withText: title, superview: nil, color: UIColor.black.dark(.white))
                .font(CustomFontBook.Bold.of(size: .large))
                .toCardSet(), xsColWidth: .Twelve)
        ])
        
        self.addRow(columns: [
            // Sync button
            Column(cardSet: actionButton
                .radius(radius: 5)
                .toCardSet()
                .margin.bottom(50)
                .withHeight(UI.scheduleViewButtonHeights),
                   xsColWidth: .Twelve).forSize(.md, .Six).forSize(.xl, .Four)
        ], anchorToBottom: true)
        
        self.actionButton = actionButton
    }
    
}
