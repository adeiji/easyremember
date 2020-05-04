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

class GRNotificationCard: UITableViewCell {
            
    static let reuseIdentifier = "NotificationCardCell"
                
    func setupUI (title: String, description: String) {
        let card = GRBootstrapElement(color: .white, anchorWidthToScreenWidth: true)
            .addRow(columns: [
                Column(cardSet: Style.label(withText: title, size: .header, superview: nil, color: .black)
                    .toCardSet().margin.left(20.0).margin.right(20.0).margin.top(20.0), colWidth: .Eleven),
                Column(cardSet: Style.label(withText: description, superview: nil, color: .black)
                    .toCardSet().margin.left(20.0).margin.right(20.0).margin.top(20.0).margin.bottom(20.0), colWidth: .Twelve)
            ], anchorToBottom: true)
        
        card.addToSuperview(superview: self.contentView, anchorToBottom: true)
        card.addShadow()
        
    }
}
