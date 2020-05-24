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

class GRNotificationCard: UICollectionViewCell {
              
    static let reuseIdentifier = "NotificationCardCell"
    
    weak var deleteButton:UIButton?
    
    /// Displays the title of the notification
    private weak var titleLabel:UILabel?
    
    /// Displays the content of the notification
    private weak var contentLabel:UILabel?
    
    private weak var bookNameLabel:UILabel?
    
    /// User presses this button and the notification is either set to active or inactive
    weak var toggleActivateButton:UIButton?
    
    var isTranslation = false
    
    var viewToBaseWidthOffOf:UIView?
    
    var showDeleteButton:Bool = true
               
    var notification:GRNotification? {
        didSet {
            if let notification = self.notification {
                if oldValue == nil {
                    self.setupUI(title: notification.caption, description: notification.description, language: notification.language, viewToCalculateWidth: self.viewToBaseWidthOffOf, bookTitle: notification.bookTitle)
                } else {
                    self.toggleButton(self.toggleActivateButton, isActive: notification.active)
                    self.titleLabel?.text = notification.caption
                    self.contentLabel?.text = notification.description
                    self.bookNameLabel?.text = "\(notification.bookTitle ?? "No Book")   \(notification.language ?? "")"
                }
            }
        }
    }
    
    func toggleButton (_ button: UIButton?, isActive: Bool? = false) {
        guard let button = button else { return }
        if isTranslation {
            button.setTitle(isActive == true ? "Cancel" : "Create Card", for: .normal)
            button.backgroundColor = isActive == true ? UIColor.EZRemember.lightRed : UIColor.EZRemember.lightGreen
            button.setTitleColor(isActive == true ? UIColor.EZRemember.lightRedButtonText : UIColor.EZRemember.lightGreenButtonText, for: .normal)
        } else {
            button.setTitle(isActive == true ? NSLocalizedString("deactivate", comment: "deactivate the card") : NSLocalizedString("activate", comment: "activate the card"), for: .normal)
            button.backgroundColor = isActive == true ? UIColor.EZRemember.lightRed : UIColor.EZRemember.lightGreen
            button.setTitleColor(isActive == true ? UIColor.EZRemember.lightRedButtonText : UIColor.EZRemember.lightGreenButtonText, for: .normal)
        }
        
    }
                
    /**
     - parameter viewToCalculateWidth: If you want this card to have it's size calculated based off of it's superview content, than set this property.  Remember though, that the size of this card's width will be based upon the width of the viewToCalculateWidth view at the time you call this method, not after it's layout has been updated.
     */
    private func setupUI (title: String, description: String, language:String?, viewToCalculateWidth: UIView? = nil, bookTitle:String? = nil, showDeleteButton:Bool = true) {
                
        let editButton = Style.largeButton(with: "Edit")
        editButton.titleLabel?.font = FontBook.allBold.of(size: .small)
        editButton.showsTouchWhenHighlighted = true
        
        let deleteButton = UIButton()
        deleteButton.contentMode = .left
        
        let toggleActivateButton = Style.largeButton(with: "")
        self.toggleButton(toggleActivateButton, isActive: self.notification?.active)
        toggleActivateButton.titleLabel?.font = CustomFontBook.Medium.of(size: .verySmall)
        toggleActivateButton.showsTouchWhenHighlighted = true
        
        // TITLE LABEL
        
        let titleLabel = Style.label(withText: title, size: .small, superview: nil, color: UIColor.black.dark(.white))
        titleLabel.numberOfLines = GRCurrentDevice.shared.size == .xs ? 3 : 2
        
        // CONTENT LABEL
        
        let contentLabel = Style.label(withText: description, superview: nil, color: UIColor.darkGray.dark(.white))
        contentLabel.numberOfLines = GRCurrentDevice.shared.size == .xs ? 3 : 4
        
        // TOP TITLE LABEL
        
        let topTitleLabel = Style.label(withText: language ?? "", superview: nil, color: UIColor.black.dark(.white))
        topTitleLabel.font(CustomFontBook.Medium.of(size: .small))
        
        // Book Title
        
        let bookTitleLabel = Style.label(withText: bookTitle ?? "No Book", superview: nil, color: UIColor.EZRemember.mainBlue.dark(.white))
        bookTitleLabel.numberOfLines = 1
        
        let card = GRBootstrapElement(color: UIColor.white.dark(Dark.mediumShadeGray), anchorWidthToScreenWidth: true,
                                      superview: viewToCalculateWidth ?? self.contentView)
                        
        if (self.showDeleteButton) {
            card.addRow(columns: [
                // Delete Button
                Column(cardSet: deleteButton
                    .withImage(named: "exit", bundle: "EZRemember")
                    .toCardSet()
                    .margin.top(20.0)
                    .margin.bottom(0),
                       xsColWidth: .Two),
                
                // TOGGLE ACTIVE BUTTON
                
                Column(cardSet: toggleActivateButton
                .radius(radius: 5)
                .toCardSet()
                .withHeight(30),
                       xsColWidth: .Five)
            ])
        }
        
        card.addRow(columns: [
            // TOP TITLE LABEL
            Column(cardSet: topTitleLabel
                .radius(radius: 5)
                .toCardSet()
                .margin.top(10)
                .margin.left(20),
                   xsColWidth: .Twelve),
        ])
        .addRow(columns: [
            Column(cardSet: titleLabel
                .font(CustomFontBook.Bold.of(size: .small))
                .toCardSet().margin.left(20.0).margin.right(20.0).margin.top(10.0), xsColWidth: .Twelve),
            // Content of the label
            Column(cardSet: contentLabel.font(CustomFontBook.Regular.of(size: .small))
                .toCardSet().margin.left(20.0).margin.right(20.0).margin.top(10.0).margin.bottom(10.0), xsColWidth: .Twelve)
        ], anchorToBottom: false)
                          
        /// CARD DETAILS - ie Book Name or Personal
        
        card.addRow(columns: [
            Column(cardSet: UIView().backgroundColor(.lightGray)
                .toCardSet()
                .anchorToViewAbove(false)
                .margin.left(20.0)
                .margin.right(20.0)
                .withHeight(1.0), xsColWidth: .Twelve),
            Column(cardSet: bookTitleLabel
                .toCardSet()
                .margin.left(20.0)
                .margin.right(20.0)
                .margin.top(0),
                   xsColWidth: .Twelve)
        ], anchorToBottom: true)
        
        card.addToSuperview(superview: self.contentView, anchorToBottom: true)
        card.addShadow()
        card.radius(radius: 0)
        
        self.deleteButton = deleteButton
        self.toggleActivateButton = toggleActivateButton
        self.titleLabel = titleLabel
        self.contentLabel = contentLabel
        self.bookNameLabel = bookTitleLabel
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
    }
}
