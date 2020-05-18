//
//  DEMainViewController+CollectionView.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/18/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import SwiftyBootstrap

class NotificationsHeaderCell : UIView {
    
    func draw () {
        let header = Style.largeCardHeader(text: "Your Notifications", superview: nil, viewAbove: nil)
        let searchBar = Style.wideTextField(withPlaceholder: "Search", superview: nil, color: UIColor.black.dark(.white))
        
        header.addRow(columns: [
            Column(cardSet: searchBar.toCardSet(), xsColWidth: .Twelve)
        ])
        
        searchBar.backgroundColor = UIColor.white.dark(Dark.coolGrey50)
        searchBar.radius(radius: 5)

        
        
    }
    
}



extension DEMainViewController: UIScrollViewDelegate, UICollectionViewDelegateFlowLayout {

    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = collectionView.bounds.width
        var cellWidth:CGFloat!
        
        switch GRCurrentDevice.shared.size {
        case .xl:
            fallthrough
        case .lg:
            cellWidth = (width - 20) / 3 // compute your cell width
        case .md:
            fallthrough
        case .sm:
            cellWidth = (width - 20) / 2 // compute your cell width
        case .xs:
            cellWidth = width - 20
        }
        
        return CGSize(width: cellWidth, height: 350)
        
     }
    
    
}
