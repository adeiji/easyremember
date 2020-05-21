//
//  Style+LargeHeader.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/7/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import SwiftyBootstrap

public extension Style {
    
    /// Add a card at the to of the screen that will serve as a header, and say whatever is text
    /// If you set the superview than this view will automatically be added to the superview, and it's last row
    /// anchored to the bottom
    class func largeCardHeader (
        text: String,
        margin:BootstrapMargin? = BootstrapMargin(
            left: .Three,
            top: .One,
            right: .Zero,
            bottom: .Three),
        superview: UIView? = nil,
        viewAbove: UIView?) -> GRBootstrapElement {
        
        let headerCard = GRBootstrapElement(color: .clear, anchorWidthToScreenWidth: true, margin: margin)
            .addRow(columns: [Column(
                cardSet: Style.label(
                    withText: text,
                    superview: nil,
                    color: UIColor.black.dark(.white))
                    .font(CustomFontBook.Regular.of(size: .logo))
                    .toCardSet(),
                        xsColWidth: .Twelve)
            ], anchorToBottom: superview != nil ? true : false)
        
        headerCard.isUserInteractionEnabled = false
        headerCard.layer.zPosition = -5
        
        if let superview = superview {
            headerCard.addToSuperview(superview: superview, viewAbove: viewAbove, anchorToBottom: false)
        }
        
        return headerCard
    }
    
}
