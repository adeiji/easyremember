//
//  GRLanguagesCard.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/9/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import SwiftyBootstrap

class DELanguagesCard: GRBootstrapElement {
    
    private var selectedLanguagesButtons = [UIButton]()
    var selectedLanguages = [String]()
    
    init(bootstrapMargin:BootstrapMargin, selectedLanguages: [String]) {
        super.init(color: .clear, margin: bootstrapMargin )
        self.setupUI(selectedLanguages: selectedLanguages)
    }
            
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func handleLanguageSelection (selected:Bool, button: UIButton) {
        guard let buttonText = button.titleLabel?.text else { return }
        guard let languageShortCode = GRNotification.getLanguageShortCodeForValue(buttonText) else { return }
        
        if !selected {
            self.selectedLanguagesButtons = self.selectedLanguagesButtons.filter({ $0 != button })
            self.selectedLanguages = self.selectedLanguages.filter({ $0 != languageShortCode })
            button.backgroundColor = UIColor.EZRemember.veryLightGray.dark(Dark.mediumShadeGray)
            button.setTitleColor(UIColor.darkText.dark(Dark.coolGrey50), for: .normal)
            return
        }
             
        self.selectedLanguagesButtons.append(button)
        self.selectedLanguages.append(languageShortCode)
        button.backgroundColor = UIColor.EZRemember.mainBlue.dark(Dark.brownishTan)
        button.setTitleColor(.white, for: .normal)
        
    }
    
    private func setupUI (selectedLanguages:[String]) {
        
        var selectNumberColumns = [Column]()
        
        GRNotification.kSupportedLanguages.forEach({ (key, value) in
            let button = Style.largeButton(with: value, backgroundColor: UIColor.EZRemember.veryLightGray.dark(Dark.mediumShadeGray), fontColor: UIColor.darkText.dark(Dark.coolGrey50))
            button.showsTouchWhenHighlighted = true
            button.radius(radius: 5)
            
            let column = Column(cardSet:
                button
                    .toCardSet()
                    .withHeight(UI.scheduleViewButtonHeights),
                        xsColWidth: .Two)
                            .forSize(.xs, .Six)
                            .forSize(.lg, .Two)
            
            selectNumberColumns.append(column)
            
            if (selectedLanguages.contains(key)) {
                self.handleLanguageSelection(selected: true, button: button)
            }
            
            button.addTargetClosure { [weak self] (languageButton) in
                guard let self = self else { return }
                self.handleLanguageSelection(selected: !self.selectedLanguagesButtons.contains(languageButton), button: languageButton)
            }
        })
        
        let selectLanguagesMessage = "Which languages would you look to recieve translations for?"
        
        let languagesCaptionLabel = Style.label(withText: "", superview: nil, color: UIColor.black.dark(Dark.coolGrey50))
        languagesCaptionLabel.attributedText = selectLanguagesMessage.addLineSpacing()
        languagesCaptionLabel.font( CustomFontBook.Medium.of(size: Style.getScreenSize() == .xs ? .small : .medium) )
        
        self
        .addRow(columns:[
            Column(cardSet: languagesCaptionLabel
                .toCardSet()
                .margin.top(50)
                .margin.bottom(50),
                   xsColWidth: .Twelve)
                
        ])
        .addRow(columns: selectNumberColumns, anchorToBottom: true)
    }
}

