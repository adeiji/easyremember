//
//  GRNotificationCard.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/4/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import SwiftyBootstrap

class GRNotificationCard: UITableViewCell {
            
    static let reuseIdentifier = "NotificationCardCell"
    
    weak var deleteButton:UIButton?
    
    /// User presses this button and the notification is either set to active or inactive
    weak var toggleActivateButton:UIButton?
               
    var notification:Notification? {
        didSet {
            if let notification = self.notification {
                if oldValue == nil {
                    self.setupUI(title: notification.caption, description: notification.description)
                } else {
                    self.toggleButton(self.toggleActivateButton, isActive: notification.active)
                }
            }
        }
    }
    
    func toggleButton (_ button: UIButton?, isActive: Bool? = false) {
        guard let button = button else { return }
        button.setTitle(self.notification?.active == true ? "Deactivate" : "Activate", for: .normal)
        button.backgroundColor = self.notification?.active == true ? UIColor.EZRemember.lightRed : UIColor.EZRemember.lightGreen
        button.setTitleColor(self.notification?.active == true ? UIColor.EZRemember.lightRedButtonText : UIColor.EZRemember.lightGreenButtonText, for: .normal)
    }
                
    func setupUI (title: String, description: String) {
        
        self.selectionStyle = .none
        
        let editButton = Style.largeButton(with: "Edit")
        editButton.titleLabel?.font = FontBook.allBold.of(size: .small)
        editButton.showsTouchWhenHighlighted = true
        
        let deleteButton = UIButton()
        
        let toggleActivateButton = Style.largeButton(with: "")
        self.toggleButton(toggleActivateButton, isActive: self.notification?.active)
        toggleActivateButton.titleLabel?.font = CustomFontBook.Medium.of(size: .verySmall)
        toggleActivateButton.showsTouchWhenHighlighted = true
        
        let card = GRBootstrapElement(color: .white, anchorWidthToScreenWidth: true)
            .addRow(columns: [
                Column(cardSet: Style.label(withText: title, size: .large, superview: nil, color: .black)
                    .font(CustomFontBook.Regular.of(size: .large))
                    .toCardSet().margin.left(20.0).margin.right(20.0).margin.top(20.0), colWidth: .Ten),
                Column(cardSet: deleteButton
                    .withImage(named: "exit", bundle: "EZRemember")
                    .toCardSet()
                    .margin.top(20.0),
                       colWidth: .Two),
                Column(cardSet: Style.label(withText: description, superview: nil, color: .darkGray)
                    .toCardSet().margin.left(20.0).margin.right(20.0).margin.top(10.0).margin.bottom(20.0), colWidth: .Twelve)
            ]).addRow(columns: [
                Column(cardSet: toggleActivateButton
                    .radius(radius: 5)
                    .toCardSet()
                    .withHeight(55),
                       colWidth: .Five)
            ], anchorToBottom: true)
        
        card.addToSuperview(superview: self.contentView, anchorToBottom: true)
        card.addShadow()
        card.radius(radius: 10.0)
        
        self.deleteButton = deleteButton
        self.toggleActivateButton = toggleActivateButton
    }
}
