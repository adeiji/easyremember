//
//  GRPurchasingColumn.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/12/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import SwiftyBootstrap

struct PurchaseableItem {
    
    let title:String
    let id:String
    let info:String
    let price:CGFloat
    let features:[String]
    let finePrint:String
    
    func getFeaturesAsString () -> NSAttributedString {
        var featuresString = ""
        self.features.forEach { (feature) in
            featuresString.append(contentsOf: "√ \(feature)\n")
        }
        
        featuresString = featuresString.trimmingCharacters(in: .whitespacesAndNewlines)
        return featuresString.addLineSpacing(amount: 20, centered: true)
    }
    
}

class GRPurchasingColumn: GRBootstrapElement {
    
    weak var purchaseButton:UIButton?
    
    func draw (item: PurchaseableItem) {
        let title = Style.label(withText: item.title, superview: nil, color: UIColor.black.dark(.white), textAlignment: .center)
        let price = Style.label(withText: "$\(item.price)", superview: nil, color: UIColor.black.dark(.white), textAlignment: .center)
        let info = Style.label(withText: item.info, superview: nil, color: UIColor.black.dark(.white), textAlignment: .center)
        let purchaseButton = Style.largeButton(with: "Start your free 7-day trial!", superview: nil, backgroundColor: UIColor.EZRemember.mainBlue.dark(Dark.brownishTan), fontColor: UIColor.white.dark(Dark.coolGrey900))
        purchaseButton.titleLabel?.font = CustomFontBook.Medium.of(size: .medium)
        let features = Style.label(withText: "", superview: nil, color: UIColor.black.dark(.white), textAlignment: .center)
        features.attributedText = item.getFeaturesAsString()
        let finePrint = Style.label(withText: item.finePrint, superview: nil, color: UIColor.black.dark(.white), textAlignment: .center)
        
        self.addRow(columns: [
            
            // TITLE
            
            Column(cardSet: title.font(CustomFontBook.Bold.of(size: .large)).toCardSet().margin.left(40).margin.right(40).margin.top(40), xsColWidth: .Twelve),
            
            // PRICE
            
            Column(cardSet: price.font(CustomFontBook.Bold.of(size: .large)).toCardSet().margin.left(40).margin.right(40).margin.top(0), xsColWidth: .Twelve),
            
            
            // INFO
            
            Column(cardSet: info.font(CustomFontBook.Regular.of(size: .medium)).toCardSet().margin.left(40).margin.right(40), xsColWidth: .Twelve),
            
            // FEATURES
            
            Column(cardSet: features.font(CustomFontBook.Medium.of(size: .medium)).toCardSet().margin.left(40).margin.right(40), xsColWidth: .Twelve),
            
            // PRICE BUTTON
            
            Column(cardSet: purchaseButton.radius(radius: 5).toCardSet().margin.bottom(10).margin.left(40).margin.right(40).withHeight(UI.scheduleViewButtonHeights), xsColWidth: .Twelve),
            
            // FINE PRINT
            
            Column(cardSet: finePrint.font(CustomFontBook.Medium.of(size: .small)).toCardSet().margin.top(0).margin.left(40).margin.right(40).margin.bottom(40), xsColWidth: .Twelve, anchorToBottom: true)
        ], anchorToBottom: true)
        
        self.purchaseButton = purchaseButton
    }
}
