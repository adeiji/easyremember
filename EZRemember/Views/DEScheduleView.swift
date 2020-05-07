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
    
    public weak var numberCard:DENumberCard?
    
    /**
     Sets up the view's UI.
     
     - parameter superview: The view responsible for showing this view
     - parameter timeSlots: The time slots that have already been selecte by the user.
     */
    func setupUI (superview: UIView, timeSlots:[Int], selecteMaxNumber: Int) -> DEScheduleView {
        
        var columns = [Column]()
        
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
                .toCardSet()
                .withHeight(90), colWidth: .Twelve))
        }
        
        let timesCaptionLabel = Style.label(withText: "", size: .small, superview: nil, color: .black)
        timesCaptionLabel.font(CustomFontBook.Regular.of(size: .small))
        
        timesCaptionLabel.attributedText = ("Select all the times you want to recieve a notification").addLineSpacing()
                        
        columns.insert(Column(cardSet: timesCaptionLabel
            .toCardSet(),
                colWidth: .Twelve), at: 0)

        let numberCard = DENumberCard(selectedNumber: selecteMaxNumber)
        
        self
        .addRow(columns: [
            Column(cardSet: numberCard
                .toCardSet()
                .margin.left(0),
                   colWidth: .Twelve)
        ])
        .addRow(columns: columns, anchorToBottom: true)
        
        self.numberCard = numberCard
        return self
    }
}
