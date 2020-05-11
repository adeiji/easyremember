//
//  DEEpubReaderController.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/7/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import UIKit
import FolioReaderKit
import SwiftyBootstrap
import RxSwift
import RxCocoa

public class DEEpubReaderController: UIViewController, FolioReaderPageDelegate, FolioReaderCenterDelegate, ShowEpubReaderProtocol  {
    
    open weak var translateWord:UIButton?
    
    public var wordToTranslate:String?
    
    public var disposeBag:DisposeBag = DisposeBag()
    
    weak var mainView:GRViewWithTableView?
    
    private var urlRelay = BehaviorRelay<[URL]>(value: [])
    
    private var ebookUrl:URL?        
    
    public var readerContainer:FolioReaderContainer?
    
    public var languages:[String] = ["en"]
    
    init(ebookUrl: URL? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.ebookUrl = ebookUrl
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }
    
    func addMoreBooksButton (viewAbove: UIView) -> UIButton {
        let getMoreBooksButton = Style.largeButton(with: "Get More eBooks", superview: mainView, backgroundColor: UIColor.EZRemember.mainBlue, fontColor: .white)
        getMoreBooksButton.titleLabel?.font = CustomFontBook.Regular.forSizeClass()
        
        getMoreBooksButton.radius(radius: 5)
        let card = GRBootstrapElement(color: .clear, anchorWidthToScreenWidth: false, margin:
            BootstrapMargin(
                left: .Three,
                top: .One,
                right: .Zero,
                bottom: .Three))
            .addRow(columns: [Column(
                cardSet: getMoreBooksButton
                    .toCardSet()
                    .withHeight(50),
                xsColWidth: .Twelve)
                    .forSize(.md, .Three)
            ], anchorToBottom: true)
                        
        card.addToSuperview(superview: self.view, viewAbove: viewAbove, anchorToBottom: false)
        
        getMoreBooksButton.addTargetClosure { [weak self] (_) in
            guard let _ = self else { return }
            guard let url = URL(string: "https://www.gutenberg.org/catalog/") else { return }
            UIApplication.shared.open(url)
        }
        
        return getMoreBooksButton
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
                        
        if let ebookUrl = self.ebookUrl {
            self.showBookReader(url: ebookUrl)
        }
                
        self.mainView = GRViewWithTableView().setup(withSuperview: self.view, header: "", rightNavBarButtonTitle: "")
        self.mainView?.backgroundColor = UIColor.white.dark(Dark.coolGrey900)
        self.mainView?.navBar.isHidden = true
        self.mainView?.tableView.register(EBookCell.self, forCellReuseIdentifier: EBookCell.identifier)
        self.mainView?.tableView.separatorStyle = .none
        self.mainView?.tableView.backgroundColor = .clear
        guard let mainView = self.mainView else { return }
        let yourBooksCard = Style.addLargeHeaderCard(text: "Your\nElectronic Books", superview: mainView, viewAbove: self.mainView?.navBar)
        
        let getMoreBooksButton = self.addMoreBooksButton(viewAbove: yourBooksCard)
        
        self.mainView?.tableView.snp.remakeConstraints({ (make) in
            make.left.equalTo(mainView).offset(40)
            make.right.equalTo(mainView).offset(40)
            make.top.equalTo(getMoreBooksButton.snp.bottom).offset(40)
            make.bottom.equalTo(mainView)
        })
        
        self.showEBooks()
        let ebookHandler = EBookHandler()
        guard let urls = ebookHandler.getUrls() else { return }
        self.urlRelay.accept(urls)
        NotificationCenter.default.addObserver(self, selector: #selector(createMenuCalled), name: .CreateMenuCalled, object: nil)
    }
    

    
    // MARK: Ebook Reader
    
    public func pageTap(_ recognizer: UITapGestureRecognizer) {
        self.translateWord?.removeFromSuperview()
        self.translateWord = nil
    }
    
    // MARK: Create Menu Called
    
    @objc public func createMenuCalled (_ notification: Notification) {
        
        guard let word = notification.userInfo?["SelectedText"] as? String else { return }
        guard let readerContainer = self.readerContainer else { return }
        self.wordToTranslate = word
        
        if self.translateWord != nil {
            return
        }
        
        let translateButton = Style.largeButton(with: "Translate", backgroundColor: UIColor.EZRemember.lightGreen, fontColor: .darkGray)
        translateButton.titleLabel?.font = CustomFontBook.Medium.of(size: .small)
        translateButton.showsTouchWhenHighlighted = true
        translateButton.radius(radius: 20.0)
        
        readerContainer.view.addSubview(translateButton)
        translateButton.snp.makeConstraints { (make) in
            make.bottom.equalTo(readerContainer.view).offset(-10)
            make.centerX.equalTo(readerContainer.view)
            make.height.equalTo(60)
            make.width.equalTo(170)
        }
        
        translateButton.addTargetClosure { [weak self] (_) in
            guard let self = self else { return }
            guard let wordToTranslate = self.wordToTranslate else { return }
            let loading = translateButton.showLoadingNVActivityIndicatorView()
            
            TranslateManager.translateText(wordToTranslate).subscribe { [weak self] (event) in
                guard let self = self else { return }
                translateButton.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: loading)
                self.translateWord?.removeFromSuperview()
                self.translateWord = nil
                if let translations = event.element {
                    let showTranslationsViewController = DEShowTranslationsViewController(translations: translations, originalWord: wordToTranslate, languages: self.languages)
                    readerContainer.present(showTranslationsViewController, animated: true, completion: nil)
                }
            }.disposed(by: self.disposeBag)
        }
        
        self.translateWord = translateButton
    }
    
    // MARK: Show Book Reader
    
    private func pushBookReaderAndSetDelegates () {
        
    }
    
    private func getBookInformation (bookPath: String?) -> BookDetails? {
        
        guard var bookPath = bookPath else { return nil }
        bookPath = bookPath.replacingOccurrences(of: "file:", with: "")
        let title = try? FolioReader.getTitle(bookPath)
        let coverImage = try? FolioReader.getCoverImage(bookPath)
        let authorName = try? FolioReader.getAuthorName(bookPath)
        
        return BookDetails(author: authorName, coverImage: coverImage ?? UIImage(named: "NoImage"), title: title)
    }
    
    
    
    // MARK: Show Ebooks
    
    /// TODO: Rename this
    public func showEBooks () {
                
        guard let tableView = self.mainView?.tableView else { return }
        
        self.urlRelay
        .bind(to:
            tableView
            .rx
            .items(cellIdentifier: EBookCell.identifier, cellType: EBookCell.self)) { [weak self] (row, url, cell) in
                guard let self = self else { return }
                let eBookHandler = EBookHandler()
                guard let name = eBookHandler.getEbookNameFromUrl(url: url) else { return }
                                                
                DispatchQueue.global(qos: .background).async {
                    guard let bookDetails = self.getBookInformation(bookPath: url.absoluteString) else { return }
                    DispatchQueue.main.async {
                        cell.fillWithContent(bookDetails: bookDetails, title: name)
                    }
                }
                
                cell.textLabel?.font = CustomFontBook.Black.of(size: .medium)
                cell.url = url
                cell.deleteButton?.addTargetClosure(closure: { [weak self] (_) in
                    guard let self = self else { return }
                    guard let url = cell.url else { return }
                    try? FileManager.default.removeItem(at: url)
                    
                    let eBookHandler = EBookHandler()
                    
                    guard var urls = eBookHandler.getUrls() else { return }
                    urls = urls.filter({ $0.path != url.path })
                    self.urlRelay.accept(urls)
                })
        }.disposed(by: self.disposeBag)
        
        tableView
        .rx
        .itemSelected
            .subscribe { [weak self] (event) in
                guard let self = self else { return }
                guard let indexPath = event.element else { return }
                self.showBookReader(url: self.urlRelay.value[indexPath.row])
        }.disposed(by: self.disposeBag)
        
    }
}
