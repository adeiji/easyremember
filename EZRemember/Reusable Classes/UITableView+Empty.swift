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

public class EmptyView {
    
    public weak var actionButton:UIButton?
    
    func getView (message: String, header:String, imageName:String, buttonTitle: String? = nil) -> UIView {
        let image = ImageHelper.image(imageName: imageName, bundle: "EZRemember")
        let imageView = UIImageView(image: image)
        imageView.addShadow()
        imageView.contentMode = .scaleAspectFit
                                
        let card = GRBootstrapElement(color: .clear, margin: BootstrapMargin(
            left: .Zero,
            top: .Zero,
            right: .Zero,
            bottom: .Zero))
        .addRow(columns: [
            
            // IMAGE VIEW
                        
            Column(cardSet: imageView
                .toCardSet()
                .margin.top(Style.isIPhoneX() ? 100 : 40)
                .withHeight(150),
                   xsColWidth: .Twelve)
            
        ])
        .addRow(columns: [
            
            // THE HEADER
            
            Column(cardSet: SwiftyStyle.label(
                withText: header,
                size: .large,
                superview: nil,
                color: UIColor.black.dark(.white),
                textAlignment: .center)
                .font(CustomFontBook.Medium.of(size: .large))
                    .toCardSet(), xsColWidth: .Twelve)
        ])
        .addRow(columns: [
            
            // THE CONTENT
            
            Column(cardSet: SwiftyStyle.label(
                withText: message,
                size: .medium,
                superview: nil,
                color: UIColor.black.dark(.white),
                textAlignment: .center)
                .font(CustomFontBook.Regular.of(size: SwiftyStyle.getScreenSize() == .xs ? .small : .medium))
                    .toCardSet()
                    .margin.left(50)
                    .margin.right(50),
                        xsColWidth: .Twelve),
            ])
        

            
        if let buttonTitle = buttonTitle {
            let actionButton = SwiftyStyle.largeButton(with: buttonTitle, backgroundColor: UIColor.EZRemember.mainBlue.dark(Dark.brownishTan))
            actionButton.showsTouchWhenHighlighted = true
            card.addRow(columns: [
                
                // ACTION BUTTON
                
                Column(cardSet: actionButton
                    .radius(radius: 10)
                    .toCardSet()
                    .margin.left(30)
                    .margin.right(30)
                    .withHeight(70.0),
                       xsColWidth: .Twelve)
            ])
            
            self.actionButton = actionButton
        }
        
        return card
    }
    
}

public extension UITableView {
    
    @discardableResult func setEmptyMessage (message: String, header:String, imageName:String, buttonTitle: String? = nil) -> UIButton? {
        
        let emptyView = EmptyView()
        let card = emptyView.getView(message: message, header: header, imageName: imageName, buttonTitle: buttonTitle)
    
        self.backgroundView = card
        self.separatorStyle = .none
        self.separatorColor = .clear
                                    
        return emptyView.actionButton
    }
    
    func reset () {
        self.backgroundView = nil
        self.separatorColor = .lightGray
    }
}

public extension UICollectionView {
    
    @discardableResult func setEmptyMessage (message: String, header:String, imageName:String, buttonTitle: String? = nil) -> UIButton? {
        
        let emptyView = EmptyView()
        let card = emptyView.getView(message: message, header: header, imageName: imageName, buttonTitle: buttonTitle)
    
        self.backgroundView = card
                                                    
        return emptyView.actionButton
    }
    
    func reset () {
        self.backgroundView = nil
    }
    
}
