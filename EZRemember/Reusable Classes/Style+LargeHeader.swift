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
    class func addLargeHeaderCard (text: String, superview: UIView, viewAbove: UIView?) -> UIView {
        let headerCard = GRBootstrapElement(color: .clear, anchorWidthToScreenWidth: true, margin: BootstrapMargin(
            left: .Three,
            top: .One,
            right: .Zero,
            bottom: .Three))
            .addRow(columns: [Column(
                cardSet: Style.label(withText: text, superview: nil, color: UIColor.black.dark(.white))
                    .font(CustomFontBook.Regular.of(size: .logo))
                        .toCardSet(), xsColWidth: .Twelve)
            ], anchorToBottom: true)
        
        headerCard.isUserInteractionEnabled = false
        headerCard.layer.zPosition = -5
        
        headerCard.addToSuperview(superview: superview, viewAbove: viewAbove, anchorToBottom: false)
        return headerCard
    }
    
}
