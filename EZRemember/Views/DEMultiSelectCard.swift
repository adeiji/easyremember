//
//  DEMultiSelectCard.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/27/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import SwiftyBootstrap
import RxSwift

class DEMultiSelectCard: GRBootstrapElement {
    
    let listOfItems:[String]
    
    let initiallySelectedItem:String?
    
    let selectedItem = PublishSubject<String?>()
    
    private var selectedButton:UIButton? {
        didSet {
            oldValue?.backgroundColor = UIColor.EZRemember.veryLightGray.dark(Dark.mediumShadeGray)
            oldValue?.setTitleColor(UIColor.darkText.dark(.white), for: .normal)
        }
        
        willSet {
            newValue?.backgroundColor = UIColor.EZRemember.mainBlue.dark(Dark.brownishTan)
            newValue?.setTitleColor(UIColor.white.dark(Dark.coolGrey900), for: .normal)
        }
    }
    
    init(listOfItems:[String], color: UIColor? = .white, anchorWidthToScreenWidth: Bool = true, margin: BootstrapMargin? = nil, superview: UIView? = nil, selectedItem:String? = nil) {
        self.listOfItems = listOfItems
        self.initiallySelectedItem = selectedItem
        super.init(color: .clear, anchorWidthToScreenWidth: anchorWidthToScreenWidth, margin: margin, superview: superview)
        self.draw()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func getColumnButton (_ caption: String) -> Column {
        let button = Style.largeButton(with: caption, backgroundColor: UIColor.EZRemember.veryLightGray.dark(Dark.mediumShadeGray), fontColor: UIColor.darkText.dark(.white))
        self.createButtonTarget(button)
        
        if caption == self.initiallySelectedItem {
            self.selectedButton = button
        }
        
        let column = Column(cardSet:
        button
            .toCardSet()
            .withHeight(UI.scheduleViewButtonHeights),
                xsColWidth: .Two)
                    .forSize(.xs, .Twelve)
                    .forSize(.md, .Four)
        
        return column
    }
    
    func createButtonTarget (_ button: UIButton) {
        button.addTargetClosure { [weak self] (button) in
            guard let self = self else { return }
            self.selectedButton = button
            self.selectedItem.onNext(button.title(for: .normal))
        }
    }
    
    func headerColumn () -> Column {
        let selectLanguagesMessage = "How would you like your notifications to appear?"
        
        let languagesCaptionLabel = Style.label(withText: "", superview: nil, color: UIColor.black.dark(Dark.coolGrey50))
        languagesCaptionLabel.attributedText = selectLanguagesMessage.addLineSpacing()
        languagesCaptionLabel.font( CustomFontBook.Medium.of(size: .medium) )
                        
        return
            Column(cardSet: languagesCaptionLabel
                .toCardSet()
                .margin.top(20)
                .margin.bottom(20),
                   xsColWidth: .Twelve)
    }
    
    func draw () {
        var columns = [Column]()
        self.listOfItems.forEach { [weak self] (item) in
            guard let self = self else { return }
            columns.append(self.getColumnButton(item))
        }
        
        self
            .addRow(columns: [self.headerColumn()])
            .addRow(columns: columns, anchorToBottom: true)
    }
}
