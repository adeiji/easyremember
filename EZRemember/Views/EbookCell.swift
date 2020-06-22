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

class EBookCell: UICollectionViewCell {
    
    static let identifier = "EBookCell"
    
    public var url:URL?
    
    weak private var titleLabel:UILabel?
    
    weak private var authorLabel:UILabel?
    
    weak private var coverImageView:UIImageView?
    
    public weak var deleteButton:UIButton?
    
    public var bookDetails:BookDetails? {
        didSet {
            self.isHidden = false
            guard let bookDetails = self.bookDetails else { return }
            self.fillWithContent(bookDetails: bookDetails)
        }
    }
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.isHidden = true
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func fillWithContent(bookDetails:BookDetails) {
        self.titleLabel?.text = bookDetails.title ?? bookDetails.fileName
        self.authorLabel?.text = "\(bookDetails.author ?? "Unknown")"
        self.coverImageView?.image = bookDetails.coverImage
    }
    
    func setCoverImage (_ image: UIImage?) {
        self.coverImageView?.image = image
    }
    
    func resetData () {
        self.isHidden = true
        self.coverImageView?.image = nil
        self.titleLabel?.text = nil
        self.authorLabel?.text = nil
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.resetData()
    }

    private func setup () {
        
        let deleteButton = Style.largeButton(with: "Delete", fontColor: .white)
        
        // TITLE
        
        let titleLabel = Style.label(withText: "", superview: nil, color: UIColor.black.dark(Dark.coolGrey50))
        
        // AUTHOR
        
        let authorLabel = Style.label(withText: "", superview: nil, color: UIColor.black.dark(Dark.coolGrey50))
        
        let zeroMargin = BootstrapMargin.noMargins()
        let bookCard = GRBootstrapElement(color: UIColor.EZRemember.veryLightGray.dark(Dark.coolGrey700), anchorWidthToScreenWidth: false, margin:zeroMargin, superview: self.contentView)
        
        let detailsCard = GRBootstrapElement(color: .clear, anchorWidthToScreenWidth: false, margin: zeroMargin)
            .addRow(columns: [
                
                // TITLE LABEL
                
                Column(cardSet: titleLabel
                    .font(CustomFontBook.Regular.of(size: .small))
                    .toCardSet()
                    .withHeight(20)
                    .margin.left(5)
                    .margin.top(10)
                    .margin.bottom(0),
                       xsColWidth: .Twelve),
                
                // AUTHOR LABEL
                
                Column(cardSet: authorLabel
                    .font(CustomFontBook.Regular.of(size: .small))
                    .toCardSet()
                    .withHeight(20)
                    .margin.left(5)
                    .margin.top(3)
                    .margin.bottom(0),
                       xsColWidth: .Twelve)
            ]).addRow(columns: [
                
                // ADD THE DELETE BUTTON
                
                Column(cardSet: deleteButton
                    .backgroundColor(UIColor.Style.grayish)
                    .toCardSet()
                    .margin.left(5)
                    .margin.top(5)
                    .margin.bottom(0)
                    .withHeight(35), xsColWidth: .Twelve)
            ], anchorToBottom: true)
        
        let coverImageView = UIImageView(image: nil)
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        
        /// IMAGE COVER VIEW ///
        bookCard.addRow(columns: [
            
            // ADD THE IMAGE TO THE LEFT
            
            Column(cardSet: coverImageView
                .toCardSet()
                .withHeight(105)
                .margin.left(0)
                .margin.top(0)
                .margin.bottom(0)
                .margin.right(0),
                   xsColWidth: .Three,
                   anchorToBottom: false),
            
            // BOOK DETAILS ADDED ON THE RIGHT HAND SIDE
            
            Column(cardSet: detailsCard.toCardSet(), xsColWidth: .Eight)
                        
        ], anchorToBottom: false)
        
        bookCard.addToSuperview(superview: self.contentView, anchorToBottom: true)
        self.deleteButton = deleteButton
        
        self.titleLabel = titleLabel
        self.authorLabel = authorLabel
        self.coverImageView = coverImageView
    }
    
}
