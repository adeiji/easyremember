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
    
    func setupUI (superview: UIView) -> DEScheduleView {
        
        var columns = [Column]()
        
        for timeSlot in 1...24  {
            let timeViewCell = DETimeViewCell(timeSlot: timeSlot).setupUI(time: "\(timeSlot):00")
            timeViewCell.selectedTime.subscribe { [weak self] (event) in
                guard let self = self else { return }
                
                if let timeSlot = event.element {
                    self.timeSlotSubject.onNext(timeSlot)
                }
            }.disposed(by: self.disposeBag)
            
            columns.append(Column(cardSet: timeViewCell.radius(radius: 10).toCardSet(), colWidth: .Twelve))
        }
        
        let timesCaptionLabel = Style.label(withText: "", size: .small, superview: nil, color: .black)
        
        timesCaptionLabel.attributedText = ("Select all the times you want to recieve a notification").addLineSpacing()
                        
        columns.insert(Column(cardSet: timesCaptionLabel
            .toCardSet(),
                colWidth: .Twelve), at: 0)
                
        self
        .addRow(columns: [
            Column(cardSet: DENumberCard().toCardSet(), colWidth: .Twelve)
        ])
        .addRow(columns: columns, anchorToBottom: true)
        
        return self
    }
}
