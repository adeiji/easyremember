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

class GRCreateNotificationCard: UIView {
    
    /// The done button for this card
    weak var addButton:UIButton?
    
    weak var titleTextField:UITextField?
    
    weak var descriptionTextView:UITextView?
    
    init(superview: UIView) {
        super.init(frame: .zero)
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
        
        let addButton = Style.largeButton(with: "Add", backgroundColor: .black, fontColor: .white)
        addButton.titleLabel?.font = FontBook.allBold.of(size: .medium)
        addButton.showsTouchWhenHighlighted = true
        self.addButton = addButton
        
        let card = GRBootstrapElement(color: .white, anchorWidthToScreenWidth: true)
        let cancelButton = self.cancelButton(card: card, superview: superview)
        
        let titleTextField = Style.wideTextField(withPlaceholder: "", superview: nil, color: .black)
        let descriptionTextView = UITextView()
                                    
        card
            .addRow(columns: [
                Column(cardSet: Style.label(withText: "Enter the headword", size: .medium, superview: nil, color: .black, textAlignment: .left)
                    .toCardSet()
                    .margin.left(30)
                    .margin.bottom(10)
                    .margin.right(30).margin.top(30),
                       colWidth: .Twelve),
                
                Column(cardSet: titleTextField
                    .backgroundColor(.white)
                    .addShadow()
                    .radius(radius: 10.0)
                    .toCardSet()
                    .margin.left(30)
                    .margin.right(30),
                       colWidth: .Twelve),
                
                Column(cardSet: Style.label(withText: "Enter the definition or other content", size: .medium, superview: nil, color: .black)
                    .toCardSet()
                    .margin.left(30).margin.right(30), colWidth: .Twelve),
                
                Column(cardSet: descriptionTextView
                    .radius(radius: 10.0)
                    .addShadow()
                    .toCardSet()
                    .withHeight(100)
                    .margin.left(30)
                    .margin.right(30),
                       colWidth: .Twelve)
            ]).addRow(columns: [
                Column(cardSet: addButton
                    .radius(radius: 25)
                    .toCardSet()
                    .margin.left(30)
                    .margin.right(30)
                    .withHeight(70.0), colWidth: .Twelve),
            ]).addRow(columns: [
                Column(cardSet: cancelButton
                    .radius(radius: 25)
                    .toCardSet()
                    .margin.left(30)
                    .margin.right(30)
                    .margin.bottom(30)
                    .withHeight(90.0), colWidth: .Twelve),
            ], anchorToBottom: true)
        
        card.radius(radius: 10.0).addShadow()
        card.slideDown(superview: superview, margin: 20)
        
        self.titleTextField = titleTextField
        self.descriptionTextView = descriptionTextView
    }
}

