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

class GRReadBookViewController: UIViewController, ShowEpubReaderProtocol, AddHelpButtonProtocol {
    
    var explanation: Explanation = Explanation(sections: [
        ExplanationSection(content:
        """
        Translating the text you read is extremely simple.  Simply do the folowing:

        -- Select a word or a phrase just like if you were going to copy it.
        -- You'll see two buttons pop up at the bottom, "Translate" and "Create Card"
        -- Click "Translate" and the app will translate the text, and show you the translations.  (To update the languages to translate text into go to the "Settings" screen)
        -- Once you see the translated cards, just click the "Create Card" button for however many translations you want to create cards for
        -- Click the "Save" button and you're done!
        """, title: "Create a card from text", image: ImageHelper.image(imageName: "translator", bundle: "EZRemember")),
        ExplanationSection(content:
        """
        Alternatively, you can also just simply create a card by clicking the "Create Card" button.  That won't translate the text but will show you the "Create a Notification" screen with the text you selected as content.
        """, title: "Translating text", image: nil)
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
    
    init(reader: FolioReaderContainer , folioReader: FolioReader, bookName: String) {
        self.readerContainer = reader
        self.bookName = bookName
        self.folioReader = folioReader
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.translateWordButton?.isHidden = true
        self.createCard?.isHidden = true
        
        if self.readerView != nil {
            return
        }
        
        let readerView:UIView = UIView()
        let translationView:UIView = UIView()
        translationView.backgroundColor = UIColor(red: 250/255, green: 250/255, blue: 250/255, alpha: 1.0).dark(Dark.epubReaderBlack)
        let backButton = GRButton(type: .Back)
        
        let mainViewCard = GRBootstrapElement(color: UIColor.white.dark(Dark.epubReaderBlack), anchorWidthToScreenWidth: true, margin: BootstrapMargin(
            left: .Zero,
            top: .Five,
            right: .Zero,
            bottom: .Zero))
        .addRow(columns: [
            
            // THE BACK BUTTON
            
            Column(cardSet: backButton.toCardSet().withHeight(self.navBarHeight), xsColWidth: .Two).forSize(.sm, .One),
            
            // THE BOOK NAME HEADER
            
            Column(cardSet: Style.label(withText: self.bookName, superview: nil, color: UIColor.black.dark(.white), textAlignment: .center)
                .font(CustomFontBook.Medium.of(size: .medium))
                .toCardSet().withHeight(self.navBarHeight)
                , xsColWidth: .Eight).forSize(.sm, .Ten),
            
            // THE NAV BAR
            
            Column(cardSet: UIView().toCardSet().withHeight(self.navBarHeight), xsColWidth: .Two).forSize(.sm, .One),
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(createMenuCalled), name: UIMenuController.willShowMenuNotification, object: nil)
        
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
        
        self.handleTranslateButtonPressed()
        self.handleCreateCardButtonPressed()
        
        self.addHelpButton(nil, superview: self.view)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.folioReader.readerCenter?.toggleBars()
        
    }
    
    func showEmptyTranslationView () {
        if self.translationView?.subviews.count == 0 {
            let emptyView = EmptyView().getView(message: "Here is where the translations will show", header: "Translations", imageName: "")
            
            let emptyViewCard = GRBootstrapElement()
            emptyViewCard.addRow(columns: [
                Column(cardSet: emptyView.toCardSet(), xsColWidth: .Twelve)
            ])
            
            emptyViewCard.addToSuperview(superview: self.translationView ?? self.view)
        }
    }
    
    // MARK: Create Menu Called
    
    @objc public func createMenuCalled (_ notification: Notification) {

        self.translateWordButton?.isHidden = false
        self.createCard?.isHidden = false
    }
    
    // MARK: Translate Button
    
    private func handleTranslateButtonPressed () {
        self.translateWordButton?.addTargetClosure { [weak self] (translateButton) in
            guard let self = self else { return }
            let loading = translateButton.showLoadingNVActivityIndicatorView()
            guard let wordsToTranslate = self.currentPage?.webView?.js("getSelectedText()") else { return }
            TranslateManager.translateText(wordsToTranslate).subscribe { [weak self] (event) in
                guard let self = self else { return }
                translateButton.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: loading)
                self.translateWordButton?.isHidden = true
                
                if let translations = event.element {
                    self.displayTranslations(translations: translations, wordsToTranslate: wordsToTranslate)
                }
            }.disposed(by: self.disposeBag)
        }
    }
    
    private func createTranslateButton () -> UIButton {
        let translateButton = Style.largeButton(with: "Translate", backgroundColor: UIColor.EZRemember.lightGreen, fontColor: .darkGray)
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
    
    private func handleCreateCardButtonPressed () {
        self.createCard?.addTargetClosure { [weak self] (createCardButton) in
            guard let self = self else { return }
            guard let wordsToTranslate = self.currentPage?.webView?.js("getSelectedText()") else { return }
            let notification = GRNotification(caption: "", description: wordsToTranslate)
            let createCardVC = GRCreateNotificationViewController(notification: notification)
            createCardVC.publishNotification.subscribe { [weak self] (event) in
                guard let self = self else { return }
                createCardButton.isHidden = true
                let manager = NotificationsManager()
                guard let notification = event.element else { return }
                manager.saveNotification(title: notification.caption, description: notification.description, deviceId: UtilityFunctions.deviceId())
                    .subscribe().disposed(by: self.disposeBag)
                NotificationCenter.default.post(name: .NotificationsSaved, object: nil, userInfo: [GRNotification.kSavedNotifications: [notification]] )
            }.disposed(by: self.disposeBag)
            self.present(createCardVC, animated: true, completion: nil)
        }
        
    }
    
    private func createCreateCardButton () -> UIButton {
        
        let createCardButton = Style.largeButton(with: "Create Card", backgroundColor: UIColor.EZRemember.mainBlue, fontColor: .white)
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
