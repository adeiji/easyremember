//
//  DeckCell.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/29/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import SwiftyBootstrap

class DeckCell: UITableViewCell {
    
    static let reuseIdentifier = "DeckCell"
    
    private weak var nameLabel:UILabel?
    
    private weak var cardCountLabel:UILabel?
    
    private weak var descriptionLabel:UILabel?
    
    weak var installButton:UIButton?
    
    weak var removeButton:UIButton?
    
    private (set) var isFinishedInstalling:Bool = false
    
    var deck:Deck? {
        didSet {
            if let deck = self.deck {
                if oldValue == nil {
                    self.addUIElements()
                }
                self.draw(deck)
            }
        }
    }
    
    func finishedInstalling () {
        self.isFinishedInstalling = true
        self.installButton?.isUserInteractionEnabled = false
        self.installButton?.backgroundColor = .clear
        self.installButton?.setTitle("Added", for: .normal)
        self.installButton?.setTitleColor(UIColor.black.dark(.white), for: .normal)
        self.installButton?.titleLabel?.font = CustomFontBook.Medium.of(size: .medium)
        self.installButton?.addTargetClosure(closure: { (_) in
            print("Do nothing when pressed...")
        })
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addUIElements () {
        
        let deckCard = GRBootstrapElement(color: .clear, superview: self.contentView)
        
        let nameLabel = Style.label(withText: "", superview: nil, color: UIColor.black.dark(.white)).font(CustomFontBook.Medium.of(size: .medium))
                        
        let cardCountLabel = Style.label(withText: "", superview: nil, color: UIColor.black.dark(.white)).font(CustomFontBook.Medium.of(size: .small))
                
        let descriptionLabel = Style.label(withText: "", superview: nil, color: UIColor.black.dark(.white)).font(CustomFontBook.Regular.of(size: .small))
        
        let useButton = Style.largeButton(with: "Add Cards", backgroundColor: UIColor.EZRemember.mainBlue.dark(Dark.brownishTan), fontColor: .white)
        useButton.titleLabel?.font = CustomFontBook.Medium.of(size: .small)
        
        let removeButton = Style.largeButton(with: "Remove", backgroundColor: UIColor.red, fontColor: .white)
        removeButton.titleLabel?.font = CustomFontBook.Medium.of(size: .small)
        
        deckCard.addRow(columns: [
            Column(cardSet: nameLabel.toCardSet().margin.bottom(0).margin.left(20), xsColWidth: .Twelve),
            Column(cardSet: cardCountLabel.toCardSet().margin.top(0).margin.left(20), xsColWidth: .Twelve),
            Column(cardSet: descriptionLabel.toCardSet().margin.left(20), xsColWidth: .Twelve),
            Column(cardSet: useButton.radius(radius: 5).toCardSet().margin.left(20).withHeight(40), xsColWidth: .Three),
            Column(cardSet: removeButton.radius(radius: 5).toCardSet().margin.left(20).withHeight(40), xsColWidth: .Three)
        ], anchorToBottom: true)
        
        deckCard.addToSuperview(superview: self.contentView, anchorToBottom: true)
        
        self.installButton = useButton
        self.nameLabel = nameLabel
        self.cardCountLabel = cardCountLabel
        self.removeButton = removeButton
        self.descriptionLabel = descriptionLabel
    }
    
    func draw (_ deck: Deck) {
        self.nameLabel?.text = deck.name
        self.cardCountLabel?.text = "\(deck.cardCount) Cards"
        self.descriptionLabel?.text = deck.description
        self.contentView.setNeedsLayout()
        self.contentView.layoutIfNeeded()
    }
}
