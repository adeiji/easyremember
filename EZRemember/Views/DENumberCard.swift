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

class DENumberCard: GRBootstrapElement, RulesProtocol {
    
    var selectedButton:UIButton? {
        didSet {
            oldValue?.backgroundColor = UIColor.EZRemember.veryLightGray.dark(Dark.mediumShadeGray)
            oldValue?.setTitleColor(UIColor.darkText.dark(.white), for: .normal)
        }
        
        willSet {
            newValue?.backgroundColor = UIColor.EZRemember.mainBlue.dark(Dark.brownishTan)
            newValue?.setTitleColor(UIColor.white.dark(Dark.coolGrey900), for: .normal)
        }
    }
    
    init(selectedNumber: Int, bootstrapMargin:BootstrapMargin) {
        super.init(color: .clear, margin: bootstrapMargin )
        self.setupUI(selectedNumber: selectedNumber)
    }
            
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI (selectedNumber: Int) {
        
        var selectNumberColumns = [Column]()
        
        for number in 1...64 {
            
            if number > 10 {
                if number % 5 != 0 {
                    continue
                }
            }
            
            let button = Style.largeButton(with: "\(number)",backgroundColor: UIColor.EZRemember.veryLightGray.dark(Dark.mediumShadeGray),
                                           fontColor: UIColor.darkText.dark(.white))
            button.showsTouchWhenHighlighted = true
            
            let column = Column(cardSet:
                button
                    .toCardSet()
                    .withHeight(UI.scheduleViewButtonHeights),
                xsColWidth: .Two)
                    .forSize(.md, .Two)
                    .forSize(.xs, .Six)
                    .forSize(.sm, .Six)
            selectNumberColumns.append(column)
            
            button.addTargetClosure { [weak self] (numberOfButton) in
                guard let self = self else { return }
                guard let buttonText = numberOfButton.titleLabel?.text else { return }
                guard let number = Int(buttonText) else { return }
                
                if self.validatePassRuleOrShowFailure(Purchasing.Rules.kMaxNotificationCards, numberToValidate: number, testing: false) {
                    self.selectedButton = numberOfButton
                }
            }
            
            if number == selectedNumber {
                self.selectedButton = button
            }
        }
        
        let maxNumberMessage = "What is the maximum number of notification cards that you want to be sent to you?  The less there are, the higher your retention rate will be."
        
        let maxNumberCaptionLabel = Style.label(withText: "", superview: nil, color: UIColor.black.dark(Dark.coolGrey50))
        maxNumberCaptionLabel.attributedText = maxNumberMessage.addLineSpacing()
        maxNumberCaptionLabel.font( CustomFontBook.Medium.of(size: Style.getScreenSize() == .xs ? .small : .medium) )
        
        self
        .addRow(columns:[
            Column(cardSet: maxNumberCaptionLabel
                .toCardSet()
                .margin.bottom(50),
                   xsColWidth: .Twelve)
                
        ])
        .addRow(columns: selectNumberColumns, anchorToBottom: true)
    }
}

