//
//  DEToggledItems.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 6/4/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import SwiftyBootstrap
import RxSwift

class DEToggledItems: GRBootstrapElement {
    
    var itemToggled = PublishSubject<(active: Bool, item: String)>()
    private let disposeBag = DisposeBag()
    
    init (items: [String:Bool], title: String, margin: BootstrapMargin) {
        super.init(color: .clear, anchorWidthToScreenWidth: true, margin: margin, superview: nil)
        self.draw(items, title: title)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func draw (_ items: [String:Bool], title: String) {
        
        self.addRow(columns: [
            Column(cardSet: Style.label(withText: title, superview: nil, color: UIColor.black.dark(.white))
                .font(CustomFontBook.Medium.of(size: .large))
                .toCardSet(), xsColWidth: .Twelve)
        ])
        
        items.keys.forEach { [weak self] (item) in
            guard let self = self else { return }
            let toggleItem = DEToggleItem(item, isOn: items[item])
            
            toggleItem.itemToggled.subscribe { [weak self] (itemToggled) in
                guard let self = self else { return }
                guard let itemToggled = itemToggled.element else { return }
                self.itemToggled.onNext(itemToggled)
            }.disposed(by: self.disposeBag)
            
            self.addRow(columns: [ (Column(cardSet: toggleItem.toCardSet(), xsColWidth: .Twelve) ) ], anchorToBottom: item == Array(items.keys).last )
        }
    }
}

class DEToggleItem: UIView {
    
    private let title:String
    let itemToggled = PublishSubject<(active: Bool, item: String)>()
    
    init(_ title: String, isOn: Bool?) {
        self.title = title
        super.init(frame: .zero)
        self.draw(isOn ?? false)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func switchChanged (_ mySwitch: UISwitch) {
        self.itemToggled.onNext((active: mySwitch.isOn, item: self.title))
    }
    
    private func draw (_ isOn: Bool) {
        let mySwitch = UISwitch()
        mySwitch.isOn = isOn
        let card = GRBootstrapElement(color: .clear, anchorWidthToScreenWidth: true, margin: BootstrapMargin.noMargins(), superview: nil)
        mySwitch.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
        
        card.addRow(columns: [
            Column(cardSet: Style.label(withText: self.title, superview: nil, color: UIColor.black.dark(.white))
                .font(CustomFontBook.Regular.of(size: .small))
                .toCardSet().margin.left(0), xsColWidth: .Nine, anchorToBottom: true).forSize(.sm, .Ten),
            Column(cardSet: mySwitch.toCardSet().margin.left(0), xsColWidth: .Three, anchorToBottom: false).forSize(.sm, .Two)
        ], anchorToBottom: true)
        
        card.addToSuperview(superview: self, viewAbove: nil, anchorToBottom: true)
    }
    
}
