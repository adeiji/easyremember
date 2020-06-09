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
import RxSwift

class DEFrequencyCard: GRBootstrapElement, RulesProtocol {
    
    let frequencyCardSelected = PublishSubject<Int>()
    
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
    
    private let originalSelectedFrequency:Int
    
    init(color: UIColor? = .white, anchorWidthToScreenWidth: Bool = true, margin: BootstrapMargin? = nil, superview: UIView? = nil, selectedFrequency:Int) {
        self.originalSelectedFrequency = selectedFrequency
        super.init(color: UIColor.white.dark(Dark.coolGrey900), anchorWidthToScreenWidth: anchorWidthToScreenWidth, margin: margin, superview: nil)
        self.setupUI(selectedFrequency: selectedFrequency)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func addButtonColumn(_ selectNumberColumns: inout [GRBootstrapElement.Column], label: String) -> UIButton {
        let button = Style.largeButton(with: label, backgroundColor: UIColor.EZRemember.veryLightGray.dark(Dark.mediumShadeGray),
                                           fontColor: UIColor.darkText.dark(.white))
        button.showsTouchWhenHighlighted = true
        let column = Column(cardSet:
            button
                .toCardSet()
                .withHeight(UI.scheduleViewButtonHeights),
                            xsColWidth: .Two)
            .forSize(.md, .Two)
            .forSize(.xs, .Twelve)
            .forSize(.sm, .Six)
        
        selectNumberColumns.append(column)
        
        return button
    }
    
    fileprivate func addMaxNumberMessage() {
        let maxNumberMessage = NSLocalizedString("frequencyMessage", comment: "The header for frequency section")
        
        let maxNumberCaptionLabel = Style.label(withText: "", superview: nil, color: UIColor.black.dark(Dark.coolGrey50))
        maxNumberCaptionLabel.attributedText = maxNumberMessage.addLineSpacing()
        maxNumberCaptionLabel.font( CustomFontBook.Medium.of(size: .medium) )
        
        self
            .addRow(columns:[
                Column(cardSet: maxNumberCaptionLabel
                    .toCardSet()
                    .margin.bottom(30)
                    .margin.top(20),
                       xsColWidth: .Twelve)
                
            ])
    }
    
    private func addFrequencyButtonPressedClosure (_ button: UIButton, frequency: Int) {
        
        // If the frequency for this button is equal to what the user has originally selected as their desired frequency than display this button as selected
        if frequency == self.originalSelectedFrequency {
            self.selectedButton = button
        }
        
        button.addTargetClosure { [weak self] (_) in
            guard let self = self else { return }
            if self.userHasSubscription(ruleName: Purchasing.Rules.kRequiresPurchase) {
                self.selectedButton = button
                self.frequencyCardSelected.onNext(frequency)
            }
        }
    }
    
    private func setupUI (selectedFrequency: Int) {
        
        var selectNumberColumns = [Column]()
        
        let tenMinutesButton = self.addButtonColumn(&selectNumberColumns, label: NSLocalizedString("everyTenMinutes", comment: "Every 10 Minutes"))
        self.addFrequencyButtonPressedClosure(tenMinutesButton, frequency: 10)
        let fifteenMinutesButton = self.addButtonColumn(&selectNumberColumns, label: NSLocalizedString("everyFifteenMinutes", comment: "Every Fifteen Minutes"))
        self.addFrequencyButtonPressedClosure(fifteenMinutesButton, frequency: 15)
        let thirtyMinutesButton = self.addButtonColumn(&selectNumberColumns, label: NSLocalizedString("everyThirtyMinutes", comment: "Every 30 Minutes"))
        self.addFrequencyButtonPressedClosure(thirtyMinutesButton, frequency: 30)
        let hourButton = self.addButtonColumn(&selectNumberColumns, label: NSLocalizedString("everyHour", comment: "Every Hour"))
        self.addFrequencyButtonPressedClosure(hourButton, frequency: 60)
        self.addMaxNumberMessage()
        self.addRow(columns: selectNumberColumns, anchorToBottom: true)
        
    }
    
}

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
        
        for number in 1...100 {
                        
            if number > 50 {
                if number % 10 != 0 {
                    continue
                }
            }
            else if number > 10 {
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
        
        let maxNumberMessage = NSLocalizedString("maxNotifications", comment: "header for maximum notifications")
        
        let maxNumberCaptionLabel = Style.label(withText: "", superview: nil, color: UIColor.black.dark(Dark.coolGrey50))
        maxNumberCaptionLabel.attributedText = maxNumberMessage.addLineSpacing()
        maxNumberCaptionLabel.font( CustomFontBook.Medium.of(size: .medium) )
        
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

