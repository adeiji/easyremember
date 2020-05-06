//
//  UITableView+Empty.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/5/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import SwiftyBootstrap

typealias SwiftyStyle = Style

public extension UITableView {
    
    func setEmptyMessage (message: String, header:String, imageName:String, buttonTitle: String? = nil) -> UIButton? {
        
        let image = ImageHelper.image(imageName: imageName, bundle: "EZRemember")
        let imageView = UIImageView(image: image)
        imageView.addShadow()
        imageView.contentMode = .scaleAspectFill
                                
        let card = GRBootstrapElement(color: .white, margin: BootstrapMargin(
            left: 0,
            top: 0,
            right: 0,
            bottom: 0))
        .addRow(columns: [
            Column(cardSet: UIView().toCardSet().withHeight(200), colWidth: .Four),
            Column(cardSet: imageView
                .toCardSet()
                .margin.top(40)
                .withHeight(150),
                   colWidth: .Four),
            Column(cardSet: UIView().toCardSet().withHeight(200), colWidth: .Four)
        ])
        .addRow(columns: [
            Column(cardSet: SwiftyStyle.label(
                withText: header,
                size: .large,
                superview: nil,
                color: .black,
                textAlignment: .center)
                .font(CustomFontBook.Medium.of(size: .large))
                    .toCardSet(), colWidth: .Twelve)
        ])
        .addRow(columns: [
            Column(cardSet: SwiftyStyle.label(
                withText: message,
                size: .medium,
                superview: nil,
                color: .black,
                textAlignment: .center)
                .font(CustomFontBook.Regular.of(size: .small))
                    .toCardSet()
                    .margin.left(50)
                    .margin.right(50),
                        colWidth: .Twelve),
            ])
        
        self.backgroundView = card
        self.separatorStyle = .none
        self.separatorColor = .clear
            
        if let buttonTitle = buttonTitle {
            let actionButton = SwiftyStyle.largeButton(with: buttonTitle, backgroundColor: UIColor.EZRemember.mainBlue)
            actionButton.showsTouchWhenHighlighted = true
            card.addRow(columns: [
                Column(cardSet: actionButton
                    .radius(radius: 10)
                    .toCardSet()
                    .margin.left(30)
                    .margin.right(30)
                    .withHeight(70.0),
                       colWidth: .Twelve)
            ])
            
            return actionButton
        }
                                    
        return nil
    }
    
    func reset () {
        self.backgroundView = nil
        self.separatorColor = .lightGray
    }
}
