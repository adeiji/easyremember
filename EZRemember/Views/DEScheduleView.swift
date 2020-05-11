//
//  DEScheduleView.swift
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

class DEScheduleView: GRBootstrapElement {
    
    let timeSlotSubject = PublishSubject<Int>()
    private let disposeBag = DisposeBag()
    
    
    /**
     Sets up the view's UI.
     
     - parameter superview: The view responsible for showing this view
     - parameter timeSlots: The time slots that have already been selecte by the user.
     */
    func setupUI (superview: UIView, timeSlots:[Int], selecteMaxNumber: Int) -> DEScheduleView {
        
        var columns = [Column]()
        
        // Generate all the labels that represent the different times that a notification can be sent
        for timeSlot in 1...24  {
            let timeViewCell = DETimeViewCell(timeSlot: timeSlot).setupUI(time: "\(timeSlot):00")
            if (timeSlots.contains(timeSlot)) {
                timeViewCell.selected = true
            }
            timeViewCell.selectedTime.subscribe { [weak self] (event) in
                guard let self = self else { return }
                
                if let timeSlot = event.element {
                    self.timeSlotSubject.onNext(timeSlot)
                }
            }.disposed(by: self.disposeBag)
            
            columns.append(Column(cardSet: timeViewCell
                .radius(radius: 10)
                .toCardSet().margin.left(20).margin.right(20)
                .withHeight(90), xsColWidth: .Twelve).forSize(.md, .Six).forSize(.xl, .Three))
        }
        
        let timesCaptionLabel = Style.label(withText: "", size: .small, superview: nil, color: UIColor.black.dark(Dark.coolGrey50))
        timesCaptionLabel.font(CustomFontBook.Medium.of(size: Style.getScreenSize() == .xs ? .small : .medium ))
        timesCaptionLabel.attributedText = ("Select all the times you want to recieve a notification").addLineSpacing()
        
        self.addRow(columns: [
            Column(cardSet: timesCaptionLabel
            .toCardSet()
            .margin.top(50)
            .margin.bottom(50),
                xsColWidth: .Twelve)
        ])
        .addRow(columns: columns, anchorToBottom: true)
        
        return self
    }
}
