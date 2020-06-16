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
    
    weak var notificationCountLabel:UILabel?
    
    let tagPressed = PublishSubject<String>()
    
    func allowNotificationsCard () -> GRBootstrapElement {
        
        let enableNotificationsButtonLocalized = NSLocalizedString("enableNotificationsButton", comment: "the enable notifications button with important added on the Notifications Header Cell")
        
        let enableNotificationsButton = Style.largeButton(with: enableNotificationsButtonLocalized, backgroundColor: UIColor.EZRemember.mainBlue.dark(Dark.brownishTan), fontColor: UIColor.white.dark(Dark.coolGrey700))

        let enableNotificationsLabelLocalized = NSLocalizedString("enableNotificationsMessageContent", comment: "The description of why enabling notifications is so important")
        
        let enableNotificationsLabel = Style.label(withText: "", superview: nil, color: UIColor.black.dark(.white))
        enableNotificationsLabel.attributedText = enableNotificationsLabelLocalized.addLineSpacing(amount: 10.0, centered: false)
        
        let card = GRBootstrapElement(color: UIColor.white.dark(Dark.coolGrey700), anchorWidthToScreenWidth: true)
        card.addRow(columns: [
            Column(cardSet: enableNotificationsLabel
                .font(CustomFontBook.Regular.of(size: .small))
                .toCardSet()
                .margin.left(40)
                .margin.right(40)
                .margin.top(40),
                   xsColWidth: .Twelve),
            Column(cardSet: enableNotificationsButton.toCardSet()
                .withHeight(50)
                .margin.left(40)
                .margin.right(40)
                .margin.bottom(40),
                   xsColWidth: .Twelve).forSize(.md, .Six)
        ], anchorToBottom: true)
        
        enableNotificationsButton.addTargetClosure { [weak self] (button) in
            guard let _ = self else { return }
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            appDelegate.setupRemoteNotifications(application: UIApplication.shared)
            button.backgroundColor = UIColor.EZRemember.lightGreen
            button.setTitleColor(UIColor.EZRemember.lightGreenButtonText, for: .normal)
            button.setTitle("Awesome!", for: .normal)
        }
        
        return card
    }
    
    func draw () {
                        
        let notificationsLocalized = NSLocalizedString("notificationsHeader", comment: "The header that says Your Notifications at the top of the notifications page")
        
        let searchLocalized = NSLocalizedString("search", comment: "placeholder for the search bar")
        
        let header = Style.largeCardHeader(text: notificationsLocalized, margin: BootstrapMargin.noMargins(), superview: nil, viewAbove: nil)
        let searchBar = Style.wideTextField(withPlaceholder: searchLocalized, superview: nil, color: UIColor.black.dark(.white))
        
        let notificationCountLabel = Style.label(withText: "", superview: nil, color: UIColor.darkGray.dark(.white)).font(CustomFontBook.Medium.of(size: .medium))
        
        if UIApplication.shared.isRegisteredForRemoteNotifications == false {
            header.addRow(columns: [
                Column(cardSet: allowNotificationsCard().toCardSet(), xsColWidth: .Twelve)
            ])
        }
        
        header.addRow(columns: [
            Column(cardSet: searchBar.toCardSet(), xsColWidth: .Twelve)
        ])
        
        searchBar.backgroundColor = UIColor.white.dark(Dark.coolGrey700)
        searchBar.radius(radius: 5)
        searchBar.placeholder = searchLocalized
        searchBar.clearButtonMode = .always

        let tags = UtilityFunctions.getTags()
        
        let allLocalized = NSLocalizedString("all", comment: "The text for all on the filter button")
        let activeLocalized = NSLocalizedString("active", comment: "The text for active on the filter button")
        let inactiveLocalized = NSLocalizedString("inactive", comment: "The text for inactive on the filter button")
        
        let scrollView = HorizontalScrollableView()
        
        var filterViews = [
            self.getTagButton(tag: allLocalized),
            self.getTagButton(tag: activeLocalized),
            self.getTagButton(tag: inactiveLocalized),
            self.getTagButton(tag: "Remembered"),
            self.getTagButton(tag: "Not Remembered")
        ]
                
                        
        tags?.forEach({ [weak self] (tag) in
            guard let self = self else { return }
            if tag.trimmingCharacters(in: .whitespacesAndNewlines) == "" { return }
            
            let tagLabel = self.getTagButton(tag: tag)
            filterViews.append(tagLabel)
        })
        
        header.addRow(columns: [
            Column(cardSet: notificationCountLabel.toCardSet(), xsColWidth: .Twelve),
            Column(cardSet: UIView().backgroundColor(UIColor.lightGray.dark(.white)).toCardSet().withHeight(1), xsColWidth: .Twelve)
        ])
        
        scrollView.content = filterViews
        
        header.addRow(columns: [
            Column(cardSet: scrollView.toCardSet().withHeight(50), xsColWidth: .Twelve)
        ], anchorToBottom: true)
        
        if self.subviews.count == 0 {
            header.addToSuperview(superview: self, anchorToBottom: true)
        }
                        
        header.isUserInteractionEnabled = true
        self.searchBar = searchBar
        self.notificationCountLabel = notificationCountLabel
    }
    
    private func getTagButton (tag: String) -> UIButton {
        let tagButton = Style.largeButton(with: tag, backgroundColor: UIColor.white.dark(Dark.coolGrey200), fontColor: UIColor.EZRemember.mainBlue)
        tagButton.titleLabel?.font = CustomFontBook.Medium.of(size: .small)
        tagButton.titleEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        tagButton.sizeToFit()
        tagButton.layer.cornerRadius = 3.0
        tagButton.addTargetClosure { [weak self] (tagButton) in
            guard let self = self else { return }
            self.tagPressed(text: tagButton.title(for: .normal))
        }
        
        return tagButton
    }
    
    @objc func tagPressed (text: String?) {
        guard let tag = text else { return }
        self.tagPressed.onNext(tag)
    }
}

extension DEMainViewController: UIScrollViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate {
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.collectionHeaderView?.searchBar?.resignFirstResponder()
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        // We have two sections, one with a header one without, this is so that we can reset just the second section, which contains the notification cards, without having to update the top header which would cause problems.
        return 2
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        // Only show a header if it's the first section
        if section == 1 {
            return CGSize.zero
        }
        
        let headerView = self.collectionHeaderView ?? self.collectionView(collectionView, viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: section))
        
        return headerView.systemLayoutSizeFitting(CGSize(width: collectionView.frame.width, height: UIView.layoutFittingExpandedSize.height),
        withHorizontalFittingPriority: .required, // Width is fixed
        verticalFittingPriority: .fittingSizeLevel) // Height can be as large as needed
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize.zero
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if section == 0 {
            return 0
        }
        
        return self.notifications.count
    }
            
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if indexPath.section == 1 {
            return UICollectionReusableView()
        }
        
        if kind == UICollectionView.elementKindSectionHeader {
            
            self.collectionHeaderView?.removeFromSuperview()
            
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: NotificationsHeaderCell.reuseIdentifier, for: indexPath) as? NotificationsHeaderCell
            headerView?.draw()
            self.collectionHeaderView = headerView
            
            return headerView ?? UICollectionReusableView()
        }
        
        if kind == UICollectionView.elementKindSectionFooter {
            return UICollectionReusableView()
        }
        
        fatalError("Unknown kind")
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GRNotificationCard.reuseIdentifier, for: indexPath) as? GRNotificationCard else {
            fatalError("This cell does not exists")
        }
                        
        return cell
        
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? GRNotificationCard else { return }
        
        cell.notification = self.notifications[indexPath.row]
        self.handleToggleActivateCard(card: cell)
        self.setupNotificationCellDeleteButton(cell: cell)
        self.handleToggleRememberedCard(card: cell)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
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
