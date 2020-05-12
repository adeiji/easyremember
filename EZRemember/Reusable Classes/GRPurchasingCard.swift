//
//  GRPurchasingCard.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/12/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import SwiftyBootstrap
import RxSwift

class GRPurchasingCard: GRBootstrapElement {
    
    let purchaseableItems:[PurchaseableItem]
    
    let purchasePressed = PublishSubject<PurchaseableItem>()
    
    init(color: UIColor? = .white, anchorWidthToScreenWidth: Bool = true, margin: BootstrapMargin? = nil, superview: UIView? = nil, purchaseableItems:[PurchaseableItem]) {
        self.purchaseableItems = purchaseableItems
        super.init(color: color, anchorWidthToScreenWidth: anchorWidthToScreenWidth, margin: margin, superview: superview)
        self.draw()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func draw () {
        var columns = [Column]()
        self.purchaseableItems.forEach { [weak self] (item) in
            guard let _ = self else { return }
            
            // EACH PURCHASING COLUMN
            let purchaseColumn = GRPurchasingColumn(color: UIColor.white.dark(Dark.coolGrey700), anchorWidthToScreenWidth: true)
            purchaseColumn.draw(item: item)
            purchaseColumn.radius(radius: 10)
            let column = Column(cardSet: purchaseColumn.toCardSet()
                .margin.left(50)
                .margin.top(50)
                .margin.right(50)
                .margin.bottom(50)
                , xsColWidth: .Twelve)
            columns.append(column)
        }
        
        self.addRow(columns: columns, anchorToBottom: true)
    }
    
}
