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
import RxSwift

class NotificationsHeaderCell : UICollectionReusableView {
    
    static let reuseIdentifier = "notificationsHeaderCell"
    
    weak var searchBar:UITextField?
    
    let tagPressed = PublishSubject<String>()
            
    fileprivate func getFilterColumn(text: String) -> GRBootstrapElement.Column {
        return Column(cardSet: self.getTagButton(tag: text).radius(radius: 5).toCardSet().withHeight(50), xsColWidth: .Six).forSize(.sm, .Two)
    }
    
    func draw () {
        
        let header = Style.largeCardHeader(text: "Your\nNotifications", margin: BootstrapMargin.noMargins(), superview: nil, viewAbove: nil)
        let searchBar = Style.wideTextField(withPlaceholder: "Search", superview: nil, color: UIColor.black.dark(.white))
        
        header.addRow(columns: [
            Column(cardSet: searchBar.toCardSet(), xsColWidth: .Twelve)
        ])
        
        searchBar.backgroundColor = UIColor.white.dark(Dark.coolGrey700)
        searchBar.radius(radius: 5)
        searchBar.placeholder = "Search"

        let tags = UtilityFunctions.getTags()
        
        // Add the first button to the columns - All Button
        var columns = [
            getFilterColumn(text: "All"),
            getFilterColumn(text: "Active"),
            getFilterColumn(text: "Inactive")
        ]
                        
        tags?.forEach({ [weak self] (tag) in
            guard let self = self else { return }
            if tag.trimmingCharacters(in: .whitespacesAndNewlines) == "" { return }
            
            let tagButton = self.getTagButton(tag: tag)
            let column = Column(cardSet: tagButton.radius(radius: 5).toCardSet().withHeight(50), xsColWidth: .Six).forSize(.md, .Two)
            columns.append(column)
        })
        
        header.addRow(columns: columns, anchorToBottom: true)
        
        if self.subviews.count == 0 {
            header.addToSuperview(superview: self, anchorToBottom: true)
        }
                        
        header.isUserInteractionEnabled = true
        self.searchBar = searchBar
    }
    
    private func getTagButton (tag: String) -> UIButton {
        let tagButton = Style.largeButton(with: tag, backgroundColor: UIColor.white.dark(Dark.coolGrey200), fontColor: UIColor.EZRemember.mainBlue)
        tagButton.titleLabel?.font = CustomFontBook.Medium.of(size: .small)
        tagButton.showsTouchWhenHighlighted = true
        self.tagPressed(button: tagButton)
        
        return tagButton
    }
    
    private func tagPressed (button: UIButton) {
        button.addTargetClosure { [weak self] (button) in
            guard let self = self else { return }
            guard let tag = button.title(for: .normal) else { return }
            self.tagPressed.onNext(tag)
        }
    }
}

extension DEMainViewController: UIScrollViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // We have two sections, one with a header one without, this is so that we can reset just the second section, which contains the notification cards, without having to update the top header which would cause problems.
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        // Only show a header if it's the first section
        if section == 1 {
            return CGSize.zero
        }
        
        let headerView = self.collectionView(collectionView, viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: section))
        
        return headerView.systemLayoutSizeFitting(CGSize(width: collectionView.frame.width, height: UIView.layoutFittingExpandedSize.height),
        withHorizontalFittingPriority: .required, // Width is fixed
        verticalFittingPriority: .fittingSizeLevel) // Height can be as large as needed
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if section == 0 {
            return 0
        }
        
        return self.notifications.count
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if indexPath.section == 1 {
            return UICollectionReusableView()
        }
        
        if kind == UICollectionView.elementKindSectionHeader {
            if let headerView = self.collectionHeaderView {
                return headerView
            }
            
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: NotificationsHeaderCell.reuseIdentifier, for: indexPath) as? NotificationsHeaderCell
            headerView?.draw()
            self.collectionHeaderView = headerView
            
            return headerView ?? UICollectionReusableView()
        }
        
        fatalError("Unknown kind")
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GRNotificationCard.reuseIdentifier, for: indexPath) as? GRNotificationCard else {
            fatalError("This cell does not exists")
        }
                        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? GRNotificationCard else { return }
        
        cell.notification = self.notifications[indexPath.row]
        self.handleToggleActivateCard(card: cell)
        self.setupNotificationCellDeleteButton(cell: cell)
    }

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
