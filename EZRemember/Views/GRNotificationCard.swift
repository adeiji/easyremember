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
    weak var toggleActivateButton:UIButton? {
        didSet {
            self.toggleActiveButtonState()
        }
    }
    
    weak var toggleRememberedButton:UIButton? {
        didSet {
            self.toggleRememberedButtonState()
        }
    }
    
    var isTranslation = false
    
    var viewToBaseWidthOffOf:UIView?
    
    var showDeleteButton:Bool = true
               
    var notification:GRNotification? {
        didSet {
            if let notification = self.notification {
                if oldValue == nil {
                    self.setupUI(notification: notification, viewToCalculateWidth: self.viewToBaseWidthOffOf)
                } else {
                    self.toggleActiveButtonState()
                    self.toggleRememberedButtonState()
                    self.titleLabel?.text = notification.caption
                    self.contentLabel?.text = notification.description
                    self.bookNameLabel?.text = "\(notification.bookTitle ?? "No Book")   \(notification.language ?? "")"
                }
            }
        }
    }
    
    private func toggleRememberedButtonState () {
        
        if self.isTranslation {
            self.toggleRememberedButton?.isHidden = true
            return
        }
        
        guard let notification = self.notification else { return }
        self.toggleButton(
            self.toggleRememberedButton,
            inactiveText: "Remembered",
            activeText: "Forgot",
            isActive: notification.remembered)
    }
    
    public func toggleActiveButtonState (_ isActive: Bool? = nil) {
        guard let notification = self.notification else { return }
        self.toggleButton(
        self.toggleActivateButton,
        inactiveText: self.isTranslation ? "Create a card" : "Activate",
        activeText: self.isTranslation ? "Cancel" : "Deactivate",
        isActive: isActive ?? notification.active)
    }
    
    func toggleButton (_ button: UIButton?, inactiveText: String, activeText: String, isActive: Bool? = false) {
        guard let button = button else { return }
        button.setTitle(isActive == true ? activeText : inactiveText, for: .normal)
        button.backgroundColor = isActive == true ? UIColor.EZRemember.lightRed : UIColor.EZRemember.lightGreen
        button.setTitleColor(isActive == true ? UIColor.EZRemember.lightRedButtonText : UIColor.EZRemember.lightGreenButtonText, for: .normal)                
    }
    
    /**
     Convert time interval since 1970 to date
     */
    private func format(duration: TimeInterval) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.doesRelativeDateFormatting = true
        let date = Date(timeIntervalSince1970: duration)

        return formatter.string(from: date)
    }
                
    fileprivate func getDeleteButtonColumn(_ deleteButton: UIButton) -> Column {
        return // Delete Button
            Column(cardSet: deleteButton
                .withImage(named: "exit", bundle: "EZRemember")
                .toCardSet()
                .margin.top(20.0)
                .margin.bottom(0),
                   xsColWidth: .Two)
    }
    
    fileprivate func getActiveButtonColumn(_ toggleActivateButton: UIButton) -> Column {
        return // TOGGLE ACTIVE BUTTON
            
            Column(cardSet: toggleActivateButton
                .radius(radius: 5)
                .toCardSet()
                .withHeight(30),
                   xsColWidth: .Four)
    }
    
    fileprivate func getRememberedButtonColumn(_ toggleRememberedButton: UIButton) -> Column {
        return Column(cardSet: toggleRememberedButton
            .radius(radius: 5)
            .toCardSet()
            .withHeight(30),
                      xsColWidth: .Four)
    }
    
    fileprivate func getWhenCreatedLabel(_ createdLabel: UILabel) -> Column {
        return // CREATED WHEN LABEL
            Column(cardSet: createdLabel
                .radius(radius: 5)
                .toCardSet()
                .margin.top(5)
                .margin.bottom(5)
                .margin.left(20),
                   xsColWidth: .Twelve)
    }
    
    fileprivate func getTopTitleLabel(_ topTitleLabel: UILabel) -> Column {
        return // TOP TITLE LABEL
            Column(cardSet: topTitleLabel
                .radius(radius: 5)
                .toCardSet()
                .margin.top(10)
                .margin.left(20),
                   xsColWidth: .Twelve)
    }
    
    fileprivate func getTitleLabel(_ titleLabel: UILabel) -> Column {
        return Column(cardSet: titleLabel
            .font(CustomFontBook.Bold.of(size: .small))
            .toCardSet().margin.left(20.0).margin.right(20.0).margin.top(10.0), xsColWidth: .Twelve)
    }
    
    fileprivate func getContentLabel(_ contentLabel: UILabel) -> Column {
        return // Content of the label
            Column(cardSet: contentLabel.font(CustomFontBook.Regular.of(size: .small))
                .toCardSet().margin.left(20.0).margin.right(20.0).margin.top(10.0).margin.bottom(10.0), xsColWidth: .Twelve)
    }
    
    fileprivate func addLine() -> Column {
        return Column(cardSet: UIView().backgroundColor(.lightGray)
            .toCardSet()
            .anchorToViewAbove(false)
            .margin.left(20.0)
            .margin.right(20.0)
            .withHeight(1.0), xsColWidth: .Twelve)
    }
    
    fileprivate func getBookTitleLabelColumn(_ bookTitleLabel: UILabel) -> Column {
        return Column(cardSet: bookTitleLabel
            .toCardSet()
            .margin.left(20.0)
            .margin.right(20.0)
            .margin.top(0),
                      xsColWidth: .Twelve)
    }
    
    /**
     - parameter viewToCalculateWidth: If you want this card to have it's size calculated based off of it's superview content, than set this property.  Remember though, that the size of this card's width will be based upon the width of the viewToCalculateWidth view at the time you call this method, not after it's layout has been updated.
     */
    private func setupUI (notification: GRNotification, viewToCalculateWidth: UIView? = nil, showDeleteButton:Bool = true) {
                
        let editButton = Style.largeButton(with: "Edit")
        editButton.titleLabel?.font = FontBook.allBold.of(size: .small)
        editButton.showsTouchWhenHighlighted = true
        
        let deleteButton = UIButton()
        deleteButton.contentMode = .left
        
        let toggleActivateButton = Style.largeButton(with: "")
        toggleActivateButton.titleLabel?.font = CustomFontBook.Medium.of(size: .verySmall)
        toggleActivateButton.showsTouchWhenHighlighted = true
        
        let toggleRememberedButton = Style.largeButton(with: "")
        
        toggleRememberedButton.titleLabel?.font = CustomFontBook.Medium.of(size: .verySmall)
        toggleRememberedButton.showsTouchWhenHighlighted = true
        
        // TITLE LABEL
        
        let titleLabel = Style.label(withText: notification.caption, size: .small, superview: nil, color: UIColor.black.dark(.white))
        titleLabel.numberOfLines = GRCurrentDevice.shared.size == .xs ? 3 : 2
        
        // CONTENT LABEL
        
        let contentLabel = Style.label(withText: notification.description, superview: nil, color: UIColor.darkGray.dark(.white))
        contentLabel.numberOfLines = GRCurrentDevice.shared.size == .xs ? 3 : 4
        
        // CREATED TIME LABEL
        
        let createdLabel = Style.label(withText: self.format(duration: notification.creationDate), superview: nil, color: UIColor.black.dark(.white))
        createdLabel.font(CustomFontBook.Medium.of(size: .small))
        
        // TOP TITLE LABEL
        
        let topTitleLabel = Style.label(withText: notification.language ?? "", superview: nil, color: UIColor.black.dark(.white))
        topTitleLabel.font(CustomFontBook.Medium.of(size: .small))
        
        // Book Title
        
        let bookTitleLabel = Style.label(withText: notification.bookTitle ?? "No Book", superview: nil, color: UIColor.EZRemember.mainBlue.dark(.white))
        bookTitleLabel.numberOfLines = 1
        
        let card = GRBootstrapElement(color: UIColor.white.dark(Dark.mediumShadeGray), anchorWidthToScreenWidth: true,
                                      superview: viewToCalculateWidth ?? self.contentView)
                        
        if (self.showDeleteButton) {
            card.addRow(columns: [
                self.getDeleteButtonColumn(deleteButton),
                self.getActiveButtonColumn(toggleActivateButton),
                self.getRememberedButtonColumn(toggleRememberedButton),
            ])
        }
        
        card.addRow(columns: [
            self.getWhenCreatedLabel(createdLabel),
        ])
        
        card.addRow(columns: [
            self.getTopTitleLabel(topTitleLabel)
        ])
        .addRow(columns: [
            self.getTitleLabel(titleLabel),
            self.getContentLabel(contentLabel)
        ], anchorToBottom: false)
                          
        /// CARD DETAILS - ie Book Name or Personal
        
        card.addRow(columns: [
            self.addLine(),
            self.getBookTitleLabelColumn(bookTitleLabel)
        ], anchorToBottom: true)
        
        card.addToSuperview(superview: self.contentView, anchorToBottom: true)
        card.addShadow()
        card.radius(radius: 0)
        
        self.deleteButton = deleteButton
        self.toggleActivateButton = toggleActivateButton
        self.titleLabel = titleLabel
        self.contentLabel = contentLabel
        self.bookNameLabel = bookTitleLabel
        self.toggleRememberedButton = toggleRememberedButton
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        
    }
}
