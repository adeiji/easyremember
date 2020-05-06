//
//  GRCreateNotificationCard.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/4/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import SwiftyBootstrap

class GRCreateNotificationCard: GRBootstrapElement {
    
    /// The done button for this card
    weak var addButton:UIButton?
    
    weak var titleTextField:UITextField?
    
    weak var descriptionTextView:UITextView?
    
    init(superview: UIView) {
        super.init(color: .white, anchorWidthToScreenWidth: true)
        self.setupUI(superview: superview)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func cancelButton (card:GRBootstrapElement, superview: UIView) -> UIButton {
        let cancelButton = Style.largeButton(with: "Cancel", backgroundColor: .red, fontColor: .white)
        cancelButton.titleLabel?.font = FontBook.allBold.of(size: .medium)
        cancelButton.showsTouchWhenHighlighted = true
        cancelButton.addTargetClosure { (_) in
            card.slideUpAndRemove(superview: superview)
        }
        
        return cancelButton
    }
    
    private func setupUI (superview: UIView) {
        self.layer.zPosition = 5
        let addButton = Style.largeButton(with: "Add", backgroundColor: .black, fontColor: .white)
        addButton.titleLabel?.font = CustomFontBook.Medium.of(size: .small)
        addButton.showsTouchWhenHighlighted = true
        addButton.backgroundColor = UIColor.EZRemember.mainBlue
        self.addButton = addButton
        
        // The cancel button
        let cancelButton = self.cancelButton(card: self, superview: superview)
        let veryLightGrayColor = UIColor(red: 246/255, green: 248/255, blue: 252/255, alpha: 1.0)
        cancelButton.titleLabel?.font = CustomFontBook.Medium.of(size: .small)
        cancelButton.setTitleColor(.darkGray, for: .normal)
        cancelButton.backgroundColor = veryLightGrayColor
        
        // Enter headword
        let titleTextField = Style.wideTextField(withPlaceholder: "", superview: nil, color: .black)
        
        // Enter description or content
        let descriptionTextView = UITextView()
                                    
        self
            .addRow(columns: [
                Column(cardSet:
                    Style.label(
                        withText: "Create a Notification",
                        superview: nil,
                        color: .black)
                        .font(CustomFontBook.Medium.of(size: .large))
                            .toCardSet()
                            .margin.left(30)
                            .margin.right(30)
                            .margin.top(30),
                                colWidth: .Twelve),
                
                Column(cardSet: Style.label(
                    withText: "Enter the headword",
                    superview: nil,
                    color: .darkGray,
                    textAlignment: .left)
                    .font(CustomFontBook.Regular.of(size: .small))
                        .toCardSet()
                        .margin.left(30)
                        .margin.bottom(30)
                        .margin.right(30).margin.top(30),
                           colWidth: .Twelve),
                
                Column(cardSet: titleTextField
                    .backgroundColor(.white)
                    .addShadow(3)
                    .radius(radius: 5.0)
                    .toCardSet()
                    .margin.left(30)
                    .margin.right(30),
                       colWidth: .Twelve),
                
                Column(cardSet: Style.label(
                    withText: "Enter the definition or other content",
                    size: .medium,
                    superview: nil,
                    color: .darkGray)
                    .font(CustomFontBook.Regular.of(size: .small))
                        .toCardSet()
                        .margin.top(30)
                        .margin.left(30)
                        .margin.right(30), colWidth: .Twelve),
                
                Column(cardSet: descriptionTextView
                    .radius(radius: 5.0)
                    .addShadow(3)
                    .toCardSet()
                    .withHeight(100)
                    .margin.left(30)
                    .margin.right(30),
                       colWidth: .Twelve)
            ]).addRow(columns: [
                Column(cardSet: addButton
                    .radius(radius: 10)
                    .toCardSet()
                    .margin.top(50)
                    .margin.left(30)
                    .margin.right(30)
                    .withHeight(110.0), colWidth: .Twelve),
            ]).addRow(columns: [
                Column(cardSet: cancelButton
                    .radius(radius: 10)
                    .toCardSet()
                    .margin.left(30)
                    .margin.right(30)
                    .margin.bottom(30)
                    .withHeight(90.0), colWidth: .Twelve),
            ], anchorToBottom: true)
        
        self.radius(radius: 10.0).addShadow()
        self.slideDown(superview: superview, margin: 20)
        
        self.titleTextField = titleTextField
        self.descriptionTextView = descriptionTextView
    }
}

