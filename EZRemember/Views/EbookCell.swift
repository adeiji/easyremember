//
//  EbookCell.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/11/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import SwiftyBootstrap

class EBookCell: UITableViewCell {
    
    static let identifier = "EBookCell"
    
    public var url:URL?
    
    weak private var titleLabel:UILabel?
    
    weak private var authorLabel:UILabel?
    
    weak private var coverImageView:UIImageView?
    
    public weak var deleteButton:UIButton?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = .clear
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func fillWithContent(bookDetails:BookDetails, title: String) {
        self.titleLabel?.text = bookDetails.title ?? title
        self.authorLabel?.text = "Written By: \(bookDetails.author ?? "Unknown")"
        self.coverImageView?.image = bookDetails.coverImage
    }
    
    private func setup () {
        self.selectionStyle = .none

        let deleteButton = Style.largeButton(with: "Delete", fontColor: .red)
        
        // TITLE
        
        let titleLabel = Style.label(withText: "", superview: nil, color: UIColor.black.dark(Dark.coolGrey50))
        
        // AUTHOR
        
        let authorLabel = Style.label(withText: "", superview: nil, color: UIColor.black.dark(Dark.coolGrey50))
        
        
        let bookCard = GRBootstrapElement(color: .clear, anchorWidthToScreenWidth: false, margin:
            BootstrapMargin(
                left: .Five,
                top: .Four,
                right: .Five,
                bottom: .Four), superview: nil)
        
        let detailsCard = GRBootstrapElement(color: .clear, anchorWidthToScreenWidth: false)
            .addRow(columns: [
                
                // TITLE LABEL
                
                Column(cardSet: titleLabel
                    .font(CustomFontBook.Medium.of(size: Style.getScreenSize() == .xs ? .medium : .large))
                    .toCardSet(),
                       xsColWidth: .Twelve),
                
                // AUTHOR LABEL
                
                Column(cardSet: authorLabel
                    .font(CustomFontBook.Regular.of(size: Style.getScreenSize() == .xs ? .small : .medium))
                    .toCardSet(),
                       xsColWidth: .Twelve)
            ]).addRow(columns: [
                
                // ADD THE DELETE BUTTON
                
                Column(cardSet: deleteButton
                .radius(radius: 5)
                .backgroundColor(UIColor.EZRemember.lightRed)
                    .toCardSet().withHeight(50), xsColWidth: .Twelve).forSize(.md, .Two)
            ], anchorToBottom: true)
        
        let coverImageView = UIImageView(image: nil)
        coverImageView.contentMode = .scaleAspectFit
        
        /// IMAGE COVER VIEW ///
        bookCard.addRow(columns: [
            // Add the image to the left
            Column(cardSet: coverImageView
                .toCardSet()
                .withHeight(250),
                   xsColWidth: .Three,
                   anchorToBottom: true),
            
            // BOOK DETAILS ADDED ON THE RIGHT HAND SIDE
            Column(cardSet: detailsCard.toCardSet(), xsColWidth: .Seven)
                        
        ], anchorToBottom: true)
        
        bookCard.addToSuperview(superview: self.contentView, anchorToBottom: true)
        self.deleteButton = deleteButton
        
        self.titleLabel = titleLabel
        self.authorLabel = authorLabel
        self.coverImageView = coverImageView
    }
    
}
