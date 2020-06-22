//
//  DEFrequencyCard.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 6/18/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
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
            .forSize(.md, .Three)
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
        
        button.addTargetClosure { [weak self] (button) in
            guard let self = self else { return }
            if self.userHasSubscription(ruleName: Purchasing.Rules.kRequiresPurchase) {
                if self.selectedButton == button { return }
                
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
