//
//  GRBootstrapElement+Delete.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/5/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import SwiftyBootstrap

open class DeleteCard: GRBootstrapElement {
    
    open weak var deleteButton:UIButton?
    open weak var cancelButton:UIButton?
    /**
     Delete button will be set on init
     */
    public override init(color: UIColor? = .white, anchorWidthToScreenWidth: Bool = true, margin: BootstrapMargin? = nil, superview:UIView? = nil) {
        super.init(color: color, anchorWidthToScreenWidth: anchorWidthToScreenWidth, margin: margin)
        self.showDeletePrompt()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func showDeletePrompt () {
        
        let deleteButton = Style.largeButton(with: "Yes", backgroundColor: UIColor.EZRemember.mainBlue)
        let cancelButton = Style.largeButton(with: "No", backgroundColor: UIColor.EZRemember.veryLightGray, fontColor: .darkText)
        cancelButton.showsTouchWhenHighlighted = true
        
        self.addRow(columns: [
            Column(cardSet: Style.label(withText: "Delete", superview: nil, color: .black)
                .font(CustomFontBook.Medium.of(size: .large))
                .toCardSet(),
                   xsColWidth: .Twelve),
            Column(cardSet: Style.label(withText: "Are you sure you want to delete this?", superview: nil, color: .black)
                .font(CustomFontBook.Regular.of(size: .small))
                .toCardSet(),
                   xsColWidth: .Twelve)
            ]).addRow(columns: [
                Column(cardSet: deleteButton
                    .radius(radius: 5)
                    .toCardSet()
                    .margin.top(30),
                       xsColWidth: .Twelve),
                Column(cardSet: cancelButton
                    .radius(radius: 5)
                    .toCardSet()
                    .margin.top(0),
                       xsColWidth: .Twelve)
            ], anchorToBottom: true)
        
        self.addShadow()
        
        self.deleteButton = deleteButton
        self.cancelButton = cancelButton
    }
    
}
