//
//  DETimeViewCell.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/6/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import SwiftyBootstrap
import RxSwift
import RxCocoa

class DETimeViewCell: UIView {
    
    weak var timeLabel:UILabel?
    
    weak var card:GRBootstrapElement?
    
    let selectedTime:PublishSubject<Int> = PublishSubject<Int>()
    
    var timeButtons = [UIButton]()
    
    let timeSlot:Int
    
    init(timeSlot:Int) {
        self.timeSlot = timeSlot
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var selected:Bool = false {
        didSet {
            if selected {
                self.card?.backgroundColor = UIColor.EZRemember.mainBlue.dark(Dark.brownishTan)
                self.timeLabel?.textColor = UIColor.white.dark(Dark.coolGrey900)
            } else {
                self.card?.backgroundColor = UIColor.EZRemember.veryLightGray.dark(Dark.mediumShadeGray)
                self.timeLabel?.textColor = UIColor.darkGray.dark(.white)
            }
        }
    }
            
    func setupUI (time: String) -> DETimeViewCell {
        
        let timeLabel = Style.label(withText: time, superview: nil, color: UIColor.darkText.dark(.white), textAlignment: .center)
        timeLabel.font(CustomFontBook.Medium.of(size: .small))
        
        let card = GRBootstrapElement(color: UIColor.EZRemember.veryLightGray.dark(Dark.mediumShadeGray), anchorWidthToScreenWidth: true, margin: BootstrapMargin(
            left: .Zero,
            top: .Zero,
            right: .Zero,
            bottom: .Zero) )
            .addRow(columns: [
                Column(cardSet: timeLabel
                    .toCardSet(),
                       xsColWidth: .Twelve)
            ], anchorToBottom: true)
        
        card.addToSuperview(superview: self, anchorToBottom: true)
            
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(timeTapped))
        self.addGestureRecognizer(tapGestureRecognizer)
        
        self.card = card
        self.timeLabel = timeLabel
        
        return self
    }
    
    @objc func timeTapped () {        
        self.selectedTime.onNext(self.timeSlot)
    }
    
}
