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

protocol CollectionViewSizeProtocol {
    
}

extension CollectionViewSizeProtocol {
    
    func getColWidth (collectionView: UICollectionView) -> CGSize {
        let width = collectionView.bounds.width
        var cellWidth:CGFloat!
        
        switch GRCurrentDevice.shared.size {
        case .xl:
            fallthrough
        case .lg:
            fallthrough
        case .md:
            cellWidth = (width - 30) / 3 // compute your cell width
        case .sm:
            cellWidth = (width - 30) / 2 // compute your cell width
        case .xs:
            cellWidth = width - 30
        }
        
        return CGSize(width: cellWidth, height: 105)
    }
    
}

public class DEEpubReaderController: UIViewController, UIScrollViewDelegate, UICollectionViewDelegateFlowLayout, ShowEpubReaderProtocol, CollectionViewSizeProtocol  {
    
    open weak var translateWordButton:UIButton?
    
    public var wordsToTranslate:String?
    
    public var disposeBag:DisposeBag = DisposeBag()
    
    weak var mainView:GRViewWithCollectionView?
    
    private var urlRelay = BehaviorRelay<[URL]>(value: [])
    
    private var ebookUrl:URL?        
    
    public var readerContainer:FolioReaderContainer?
    
    weak var collectionView:UICollectionView?
    
    var bookDetails:[String:BookDetails] = [String:BookDetails]()
    
    init(ebookUrl: URL? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.ebookUrl = ebookUrl
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let ebookHandler = EBookHandler()
        guard let urls = ebookHandler.getUrls() else { return }
        self.urlRelay.accept(urls)
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
                
        let mainView = GRViewWithCollectionView().setup(superview: self.view, columns: 3, header: "Your\nElectronic Books", addNavBar: false)
        mainView.backgroundColor = UIColor.white.dark(Dark.coolGrey900)
        mainView.collectionView?.register(EBookCell.self, forCellWithReuseIdentifier: EBookCell.identifier)
        mainView.collectionView?.backgroundColor = .clear
        mainView.addToSuperview(superview: self.view, viewAbove: nil, anchorToBottom: true)
        self.mainView = mainView
        self.collectionView = mainView.collectionView
                                
        // Bind our the url relay
        self.showEBooks()
        NotificationCenter.default.addObserver(self, selector: #selector(shouldShowMenu(_:)), name: .CreateMenuCalled, object: nil)
    }
    
    @objc private func shouldShowMenu(_ notification: Notification) {
        self.createMenuCalled(notification)
    }

    // MARK: Ebook Reader
    
    public func pageTap(_ recognizer: UITapGestureRecognizer) {
        self.translateWordButton?.removeFromSuperview()
        self.translateWordButton = nil
    }
        
    // MARK: Show Book Reader
    
    private func pushBookReaderAndSetDelegates () {
        
    }
    
    private func getBookInformation (bookPath: String?, fileName:String) -> BookDetails? {
        guard let fullUrl = bookPath else { return nil }
        guard var bookPath = bookPath else { return nil }
        
        bookPath = bookPath.replacingOccurrences(of: "file:", with: "")
        let title = try? FolioReader.getTitle(bookPath)
        let coverImage = try? FolioReader.getCoverImage(bookPath)
        let authorName = try? FolioReader.getAuthorName(bookPath)
        let bookDetails = BookDetails(author: authorName, coverImage: coverImage ?? UIImage(named: "NoImage"), title: title, url: bookPath, fileName: fileName)
        self.bookDetails[fullUrl] = bookDetails
        
        return bookDetails
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.collectionView?.reloadData()
    }
    
    
    // MARK: Show Ebooks
    
    /// TODO: Rename this
    public func showEBooks () {
                
        guard let collectionView = self.mainView?.collectionView else { return }
        let loading = self.mainView?.showLoadingNVActivityIndicatorView()
        collectionView.rx.setDelegate(self).disposed(by: self.disposeBag)
        
        self.urlRelay
        .bind(to:
            collectionView
            .rx
            .items(cellIdentifier: EBookCell.identifier, cellType: EBookCell.self)) { [weak self] (row, url, cell) in
                self?.mainView?.showFinishedLoadingNVActivityIndicatorView(activityIndicatorView: loading)
                guard let self = self else { return }
                let eBookHandler = EBookHandler()
                
                if cell.url == nil { cell.url = url }
                
                // Get the file name of the Ebook
                guard let name = eBookHandler.getEbookNameFromUrl(url: url) else { return }
                guard let bookDetails = self.getBookInformation(bookPath: url.absoluteString, fileName: name) else { return }
                cell.bookDetails = bookDetails
                    
                // Delete button
                cell.deleteButton?.addTargetClosure(closure: { [weak self] (_) in
                    guard let self = self else { return }
                    guard let url = cell.url else { return }
                    
                    let deleteCard = DeleteCard()
                    deleteCard.draw(superview: self.view)
                    
                    deleteCard.okayButton?.addTargetClosure(closure: { [weak self] (_) in
                        guard let self = self else { return }
                        
                        try? FileManager.default.removeItem(at: url)
                        let eBookHandler = EBookHandler()
                        
                        guard var urls = eBookHandler.getUrls() else { return }
                        urls = urls.filter({ $0.path != url.path })
                        self.urlRelay.accept(urls)
                        deleteCard.close()
                    })
                    
                    deleteCard.cancelButton?.addTargetClosure(closure: { [weak self] (_) in
                        guard let _ = self else { return }
                        deleteCard.close()
                        
                    })
                })
        }.disposed(by: self.disposeBag)
        
        collectionView
        .rx
        .itemSelected
            .subscribe { [weak self] (event) in
                guard let self = self else { return }
                guard let indexPath = event.element else { return }
                self.showBookReader(url: self.urlRelay.value[indexPath.row])
        }.disposed(by: self.disposeBag)
        
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.getColWidth(collectionView: collectionView)
     }
}
