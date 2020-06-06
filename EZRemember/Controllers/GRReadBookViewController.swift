//
//  GRReadBookViewController.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/8/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import SwiftyBootstrap
import FolioReaderKit

class GRReadBookViewController: GRBootstrapViewController, ShowEpubReaderProtocol, AddHelpButtonProtocol, TranslationProtocol {
    
    var explanation: Explanation = Explanation(sections: [
        ExplanationSection(content: NSLocalizedString("readBookTranslationExplanation", comment: "The first paragraph of the read translation explanation"), title: NSLocalizedString("translateTextTitle", comment: "The title for the section about translating text on the Read book page"), image: ImageHelper.image(imageName: "translator", bundle: "EZRemember")),
        ExplanationSection(content: NSLocalizedString("createCardExplanation", comment: "Explanation for creating a card from text on the read book view controller"), title: "Create a card", image: nil)
        ])
    
    /// The container that shows our epub reader
    var readerContainer: FolioReaderContainer?
    
    /// The current words taht need to be translated
    var wordsToTranslate: String?
    
    /// The name of the book
    let bookName:String
    
    /// The height of the nav bar
    let navBarHeight:CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 75 : 50
    
    /// Screen that displays the ePub reader
    weak var readerView:UIView?
    
    /// Screen that shows the translations after the user presses the translate button
    weak var translationView:UIView?
    
    /// The current page
    private var currentPage:FolioReaderPage?
    
    /// Display the reader
    private var folioReader:FolioReader
    
    /// Shows the screen to translate
    open weak var translateWordButton:UIButton?
    
    /// Shows the to create a new card
    open weak var createCard:UIButton?
    
    internal var disposeBag = DisposeBag()
    
    private var headerLabel:UILabel?
    
    private var translatingIndicator:UILabel?
    
    init(reader: FolioReaderContainer , folioReader: FolioReader, bookName: String) {
        self.readerContainer = reader
        self.bookName = bookName
        self.folioReader = folioReader
                
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    deinit {
        print("Deinit called")
        self.readerView?.removeFromSuperview()
        guard let readerContainer = self.readerContainer else { return }
        self.removeChildViewController(readerContainer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
                         
        if self.readerView != nil {
            return
        }
                
        if (UtilityFunctions.isFirstTime("reading a book")) {
            self.showExplanationViewController()
        }
                      
        NotificationCenter.default.addObserver(self, selector: #selector(handleTranslateButtonPressed), name: .TranslateButtonPressed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleCreateCardButtonPressed), name: .CreateCardButtonPressed, object: nil)
        
        let readerView:UIView = UIView()
        let translationView:UIView = UIView()
        translationView.backgroundColor = UIColor(red: 250/255, green: 250/255, blue: 250/255, alpha: 1.0).dark(Dark.epubReaderBlack)
        let backButton = GRButton(type: .Back)
        
        let topMargin:CGFloat = Style.isIPhoneX() ? 30 : 0
        
        let bookNameLabel = Style.label(withText: self.bookName, superview: nil, color: UIColor.black.dark(.white), textAlignment: .center)
        
        let mainViewCard = GRBootstrapElement(color: UIColor.white.dark(Dark.epubReaderBlack), anchorWidthToScreenWidth: true, margin: BootstrapMargin(
            left: .Zero,
            top: .Five,
            right: .Zero,
            bottom: .Zero))
        .addRow(columns: [
            
            // THE BACK BUTTON
            
            Column(cardSet: backButton.toCardSet().withHeight(self.navBarHeight).margin.top(topMargin), xsColWidth: .Two).forSize(.sm, .One),
            
            // THE BOOK NAME HEADER
            
            Column(cardSet: bookNameLabel
                .font(CustomFontBook.Medium.of(size: .medium))
                .toCardSet().withHeight(self.navBarHeight).margin.top(topMargin)
                , xsColWidth: .Eight).forSize(.sm, .Ten),
            
            // THE NAV BAR
            
            Column(cardSet: UIView().toCardSet().withHeight(self.navBarHeight).margin.top(topMargin), xsColWidth: .Two).forSize(.sm, .One),
            ]).addRow(columns: [
                
                // THE READER VIEW
                
                Column(cardSet: readerView.toCardSet(), xsColWidth: .Twelve, anchorToBottom: true)
                    .forSize(.md, .Eight),
                
                // THE TRANSLATION VIEW
                
                Column(cardSet: translationView.toCardSet().margin.bottom(0), xsColWidth: .Zero) // Remove this when the screen is extra small
                    .forSize(.md, .Four)
            ], anchorToBottom: true)
                        
        mainViewCard.addToSuperview(superview: self.view, anchorToBottom: true)
        
        self.readerView = readerView
        self.translationView = translationView
                        
        self.view.backgroundColor = UIColor.white.dark(Dark.epubReaderBlack)
        self.readerView?.backgroundColor = UIColor.white.dark(Dark.epubReaderBlack)
        
        backButton.addTargetClosure { [weak self] (_) in
            guard let self = self else { return }
            self.navigationController?.popViewController(animated: true)
        }
        
        self.showEmptyTranslationView()
        
        guard let readerContainer = self.readerContainer else { return }
        self.addChildViewControllerWithView(readerContainer, toView: self.readerView)
        self.readerContainer?.view.subviews.first?.snp.makeConstraints({ (make) in
            make.edges.equalTo(readerView)
        })
        self.folioReader.readerCenter?.pageDelegate = self
        self.folioReader.readerCenter?.delegate = self
        self.folioReader.nightMode = self.traitCollection.userInterfaceStyle == .dark
        
        self.translateWordButton = self.createTranslateButton()
        self.createCard = self.createCreateCardButton()
        self.headerLabel = bookNameLabel
                        
        self.addHelpButton(nil, superview: self.view)
        
        let translatingIndicatorLabel = Style.label(withText: "Translating...", superview: nil, color: .white, textAlignment: .center, backgroundColor: UIColor.EZRemember.mainBlue)
        translatingIndicatorLabel.font = CustomFontBook.Medium.of(size: .medium)
        mainViewCard.addSubview(translatingIndicatorLabel)
        translatingIndicatorLabel.snp.makeConstraints { (make) in
            make.left.equalTo(mainViewCard)
            make.right.equalTo(mainViewCard)
            make.bottom.equalTo(mainViewCard)
            make.height.equalTo(50)
        }
        translatingIndicatorLabel.isHidden = true
        self.translatingIndicator = translatingIndicatorLabel
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()        
    }
    
    func showEmptyTranslationView () {
        if self.translationView?.subviews.count == 0 {
            let emptyView = EmptyView().getView(message: NSLocalizedString("emptyTranslationMessage", comment: "The message that appears on the translation view controller when there are no translations there"), header: NSLocalizedString("emptyTranslationMessageTitle", comment: "The title that will show when there are no translations on the translations view controller/collection view"), imageName: "")
            
            let emptyViewCard = GRBootstrapElement()
            emptyViewCard.addRow(columns: [
                Column(cardSet: emptyView.toCardSet(), xsColWidth: .Twelve)
            ])
            
            emptyViewCard.addToSuperview(superview: self.translationView ?? self.view)
        }
    }
    
    // MARK: Translate Button
    
    @objc private func handleTranslateButtonPressed () {
         
        guard let wordsToTranslate = self.currentPage?.webView?.js("getSelectedText()") else { return }
        self.translationView?.showLoadingNVActivityIndicatorView()
        
        if GRDevice.smallerThan(.md) {
            self.headerLabel?.text = "Translating..."
            self.translatingIndicator?.isHidden = false
        }
        
        self.translateButtonPressed(nil, wordsToTranslate: wordsToTranslate) { [weak self] (translations) in
            guard let self = self else { return }
            self.headerLabel?.text = self.bookName
            self.translatingIndicator?.isHidden = true
            self.translationView?.showFinishedLoadingNVActivityIndicatorView()
            self.translationView?.subviews.forEach({ [weak self] (subview) in
                guard let _ = self else { return }
                subview.removeFromSuperview()
            })
            
            self.displayTranslations(translations: translations, wordsToTranslate: wordsToTranslate)
        }
        
    }
    
    private func createTranslateButton () -> UIButton {
        let translateButton = Style.largeButton(with: NSLocalizedString("translateButton", comment: "The text for the translate button"), backgroundColor: UIColor.EZRemember.lightGreen, fontColor: .darkGray)
        translateButton.titleLabel?.font = CustomFontBook.Medium.of(size: .small)
        translateButton.showsTouchWhenHighlighted = true
        translateButton.radius(radius: 30.0)
        translateButton.isHidden = true
        
        self.readerView?.addSubview(translateButton)
        translateButton.snp.makeConstraints { (make) in
            make.bottom.equalTo(self.readerView ?? self.view).offset(-10)
            make.right.equalTo(self.readerView?.snp.centerX ?? self.view.snp.centerX).offset(-10)
            make.height.equalTo(60)
            make.width.equalTo(170)
        }
        
        return translateButton
    }
    
    // MARK: Create Button
    
    @objc private func handleCreateCardButtonPressed () {
                    
        guard let wordsToTranslate = self.currentPage?.webView?.js("getSelectedText()") else { return }
        
        let notification = GRNotification(caption: wordsToTranslate, description: "")
        
        let createCardVC = GRNotificationViewController(notification: notification)
        
        createCardVC.publishNotification.subscribe { [weak self] (event) in
            guard let self = self else { return }
            
            let manager = NotificationsManager()
            
            guard let notification = event.element else { return }
            
            manager.saveNotification(title: notification.caption, description: notification.description, deviceId: UtilityFunctions.deviceId())
                .subscribe().disposed(by: self.disposeBag)
            
            NotificationCenter.default.post(name: .NotificationsSaved, object: nil, userInfo: [GRNotification.kSavedNotifications: [notification]] )
        }.disposed(by: self.disposeBag)
    
        self.present(createCardVC, animated: true, completion: nil)
        
        
    }
    
    private func createCreateCardButton () -> UIButton {
        
        let createCardButton = Style.largeButton(with: NSLocalizedString("createCardButton", comment: "The text for the create card button on the read book view controller"), backgroundColor: UIColor.EZRemember.mainBlue, fontColor: .white)
        createCardButton.titleLabel?.font = CustomFontBook.Medium.of(size: .small)
        createCardButton.showsTouchWhenHighlighted = true
        createCardButton.radius(radius: 30.0)
        createCardButton.isHidden = true
        
        self.readerView?.addSubview(createCardButton)
        createCardButton.snp.makeConstraints { (make) in
            make.bottom.equalTo(self.readerView ?? self.view).offset(-10)
            make.left.equalTo(self.readerView?.snp.centerX ?? self.view.snp.centerX).offset(10)
            make.height.equalTo(60)
            make.width.equalTo(170)
        }
                
        return createCardButton
    }
    
    // MARK: Display Translations
    
    private func displayTranslations (translations: Translations, wordsToTranslate: String) {
        let showTranslationsViewController = DEShowTranslationsViewController(translations: translations, originalWord: wordsToTranslate, languages: ScheduleManager.shared.getLanguages(), bookTitle: self.bookName)
        
        if !GRDevice.smallerThan(.md) {
            self.translationView?.subviews.forEach({ [weak self] (subview) in
                guard let _ = self else { return }
                subview.removeFromSuperview()
            })
            
            self.addChildViewControllerWithView(showTranslationsViewController, toView: self.translationView)
        } else {
            showTranslationsViewController.view.backgroundColor = UIColor.white.dark(Dark.coolGrey900)
            self.present(showTranslationsViewController, animated: true, completion: nil)
        }
    }
    
    // MARK: Ebook Reader
    
    public func pageTap(_ recognizer: UITapGestureRecognizer) {
        self.translateWordButton?.isHidden = true
        self.createCard?.isHidden = true
    }
        
    func pageDidAppear(_ page: FolioReaderPage) {                                
        self.currentPage = page
    }
    
}
