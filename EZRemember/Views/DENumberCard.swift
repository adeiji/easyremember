//
//  DENumberCard.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/6/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import SwiftyBootstrap

class DENumberCard: GRBootstrapElement {
    
    var selectedNumberButton:UIButton? {
        didSet {
            oldValue?.backgroundColor = UIColor.EZRemember.veryLightGray
            oldValue?.setTitleColor(.darkText, for: .normal)
        }
        
        willSet {
            newValue?.backgroundColor = UIColor.EZRemember.mainBlue
            newValue?.setTitleColor(.white, for: .normal)
        }
    }
    
    override init(color: UIColor? = .white, anchorWidthToScreenWidth: Bool = true, margin: BootstrapMargin? = nil) {
        super.init(color: color, anchorWidthToScreenWidth: anchorWidthToScreenWidth, margin: margin)
        self.setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI () {
        
        var selectNumberColumns = [Column]()
        
        for number in 1...12 {
            let button = Style.largeButton(with: "\(number)",backgroundColor: UIColor.EZRemember.veryLightGray, fontColor: .darkText)
            button.showsTouchWhenHighlighted = true
            button.radius(radius: 5)
            
            let column = Column(cardSet:
                button
                    .toCardSet(),
                        colWidth: .Two)
            selectNumberColumns.append(column)
            
            button.addTargetClosure { [weak self] (numberOfButton) in
                self?.selectedNumberButton = numberOfButton
            }
        }
        
        let maxNumberMessage = "What is the maximum number of notification cards that you want to be sent to you?  The less there are, the higher your retention rate will be."
        
        let maxNumberCaptionLabel = Style.label(withText: "", superview: nil, color: .black)
        maxNumberCaptionLabel.attributedText = maxNumberMessage.addLineSpacing()
        
        self
        .addRow(columns:[
            Column(cardSet: maxNumberCaptionLabel
                .font(CustomFontBook.Regular.of(size: .small))
                .toCardSet(),
                   colWidth: .Twelve)
                
        ])
        .addRow(columns: selectNumberColumns, anchorToBottom: true)
    }
}

