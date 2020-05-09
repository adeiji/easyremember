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
    
    init(selectedNumber: Int) {
        super.init(color: .white, margin: BootstrapMargin(left: 40, top: 0, right: 40, bottom: 0) )
        self.setupUI(selectedNumber: selectedNumber)
    }
            
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI (selectedNumber: Int) {
        
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
            
            if number == selectedNumber {
                self.selectedNumberButton = button
            }
        }
        
        let maxNumberMessage = "What is the maximum number of notification cards that you want to be sent to you?  The less there are, the higher your retention rate will be."
        
        let maxNumberCaptionLabel = Style.label(withText: "", superview: nil, color: .black)
        maxNumberCaptionLabel.attributedText = maxNumberMessage.addLineSpacing()
        maxNumberCaptionLabel.font( CustomFontBook.Medium.of(size: Style.getScreenSize() == .sm ? .small : .medium) )
        
        self
        .addRow(columns:[
            Column(cardSet: maxNumberCaptionLabel
                .toCardSet()
                .margin.bottom(50),
                   colWidth: .Twelve)
                
        ])
        .addRow(columns: selectNumberColumns, anchorToBottom: true)
    }
}

