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
    
    /// Displays the title of the notification
    private weak var titleLabel:UILabel?
    
    /// Displays the content of the notification
    private weak var contentLabel:UILabel?
    
    /// User presses this button and the notification is either set to active or inactive
    weak var toggleActivateButton:UIButton?
    
    var isTranslation = false
    
    var viewToBaseWidthOffOf:UIView?
               
    var notification:GRNotification? {
        didSet {
            if let notification = self.notification {
                if oldValue == nil {
                    self.setupUI(title: notification.caption, description: notification.description, language: notification.language, viewToCalculateWidth: self.viewToBaseWidthOffOf)
                } else {
                    self.toggleButton(self.toggleActivateButton, isActive: notification.active)
                    self.titleLabel?.text = notification.caption
                    self.contentLabel?.text = notification.description
                }
            }
        }
    }
    
    func toggleButton (_ button: UIButton?, isActive: Bool? = false) {
        guard let button = button else { return }
        if isTranslation {
            button.setTitle(self.notification?.active == true ? "Cancel" : "Create Card", for: .normal)
            button.backgroundColor = self.notification?.active == true ? UIColor.EZRemember.lightRed : UIColor.EZRemember.lightGreen
            button.setTitleColor(self.notification?.active == true ? UIColor.EZRemember.lightRedButtonText : UIColor.EZRemember.lightGreenButtonText, for: .normal)
        } else {
            button.setTitle(self.notification?.active == true ? "Deactivate" : "Activate", for: .normal)
            button.backgroundColor = self.notification?.active == true ? UIColor.EZRemember.lightRed : UIColor.EZRemember.lightGreen
            button.setTitleColor(self.notification?.active == true ? UIColor.EZRemember.lightRedButtonText : UIColor.EZRemember.lightGreenButtonText, for: .normal)
        }
        
    }
                
    /**
     - parameter viewToCalculateWidth: If you want this card to have it's size calculated based off of it's superview content, than set this property.  Remember though, that the size of this card's width will be based upon the width of the viewToCalculateWidth view at the time you call this method, not after it's layout has been updated.
     */
    private func setupUI (title: String, description: String, language:String?, viewToCalculateWidth: UIView? = nil) {
        
        self.selectionStyle = .none
        
        let editButton = Style.largeButton(with: "Edit")
        editButton.titleLabel?.font = FontBook.allBold.of(size: .small)
        editButton.showsTouchWhenHighlighted = true
        
        let deleteButton = UIButton()
        
        let toggleActivateButton = Style.largeButton(with: "")
        self.toggleButton(toggleActivateButton, isActive: self.notification?.active)
        toggleActivateButton.titleLabel?.font = CustomFontBook.Medium.of(size: .verySmall)
        toggleActivateButton.showsTouchWhenHighlighted = true
        
        let titleLabel = Style.label(withText: title, size: .large, superview: nil, color: .black)
        let contentLabel = Style.label(withText: description, superview: nil, color: .darkGray)
        
        let topTitleLabel = Style.label(withText: language ?? "", superview: nil, color: .black)
        topTitleLabel.font(CustomFontBook.Medium.of(size: Style.getScreenSize() == .sm ? .medium : .large))
        
        let card = GRBootstrapElement(color: .white, anchorWidthToScreenWidth: true,
                                      superview: viewToCalculateWidth ?? self.contentView)
            .addRow(columns: [
                // Delete Button
                Column(cardSet: topTitleLabel
                    .toCardSet()
                    .margin.top(20)
                    .margin.left(20),
                       colWidth: .Ten),
                // Delete Button
                Column(cardSet: deleteButton
                    .withImage(named: "exit", bundle: "EZRemember")
                    .toCardSet()
                    .margin.top(20.0),
                       colWidth: .Two)
            ])
            .addRow(columns: [
                Column(cardSet: titleLabel
                    .font(CustomFontBook.Regular.of(size: .large))
                    .toCardSet().margin.left(20.0).margin.right(20.0).margin.top(20.0), colWidth: .Twelve),
                // Content of the label
                Column(cardSet: contentLabel.font(CustomFontBook.Regular.of(size: Style.getScreenSize() == .sm ? .small : .medium))
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
        self.titleLabel = titleLabel
        self.contentLabel = contentLabel
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
    }
}
