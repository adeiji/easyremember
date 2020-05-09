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
    
    private let kApplicationDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    
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
    
    public override func viewDidLoad() {
        super.viewDidLoad()
                        
        if let ebookUrl = self.ebookUrl {
            self.showBookReader(url: ebookUrl)
        }
                
        self.mainView = GRViewWithTableView().setup(withSuperview: self.view, header: "", rightNavBarButtonTitle: "")
        self.mainView?.navBar.isHidden = true
        self.mainView?.tableView.register(EBookCell.self, forCellReuseIdentifier: EBookCell.identifier)
        self.mainView?.tableView.separatorStyle = .none
        let yourNotificationsCard = Style.addLargeHeaderCard(text: "Your\nElectronic Books", superview: self.view, viewAbove: self.mainView?.navBar)
        guard let mainView = self.mainView else { return }
        
        self.mainView?.tableView.snp.remakeConstraints({ (make) in
            make.left.equalTo(mainView).offset(40)
            make.right.equalTo(mainView).offset(40)
            make.top.equalTo(yourNotificationsCard.snp.bottom)
            make.bottom.equalTo(mainView)
        })
        
        self.showEBooks()
        guard let urls = self.getUrls() else { return }
        self.urlRelay.accept(urls)
        NotificationCenter.default.addObserver(self, selector: #selector(createMenuCalled), name: .CreateMenuCalled, object: nil)
    }
    
    func getUrls () -> [URL]? {
        guard let resourceURL = Bundle.main.resourceURL else { return nil }
        guard let applicationDirUrl = URL(string: kApplicationDirectory) else { return nil }
        
        do {
            var urls = try FileManager().contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            if let booksInInbox = FileManager().urls(for: "/Inbox") {
                urls.append(contentsOf: booksInInbox)
            }
            
            let booksInAppDirUrls = try FileManager().contentsOfDirectory(at: applicationDirUrl, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            urls.append(contentsOf: booksInAppDirUrls)
            
            urls = self.removeAllNonEpubFiles(urls: urls)
            return urls
        } catch {
            print(error.localizedDescription)
        }

        return nil
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
        
        return BookDetails(author: authorName, coverImage: coverImage, title: title)
    }
    
    // MARK: Remove All Non Epub Files
    
    private func removeAllNonEpubFiles (urls: [URL]) -> [URL] {
        
        return urls.filter { (url) -> Bool in
            guard var startOfFileEnding = url.absoluteString.lastIndex(of: ".") else { return false }
            startOfFileEnding = url.absoluteString.index(startOfFileEnding, offsetBy: 1)
            
            let fileEnding = url.absoluteString[startOfFileEnding...]
            if fileEnding.lowercased().contains("epub") == false {
                return false
            }
            
            return true
        }
                        
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
                guard let bookDetails = self.getBookInformation(bookPath: url.absoluteString) else { return }
                guard let name = self.getEbookNameFromUrl(url: url) else { return }
                cell.setup(bookDetails: bookDetails, title: name)
                cell.textLabel?.font = CustomFontBook.Black.of(size: .medium)
                cell.url = url
                cell.deleteButton?.addTargetClosure(closure: { [weak self] (_) in
                    guard let self = self else { return }
                    guard let url = cell.url else { return }
                    try? FileManager.default.removeItem(at: url)
                    guard var urls = self.getUrls() else { return }
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
    
    private func getEbookNameFromUrl (url: URL) -> String? {
        
        guard var startOfName = url.absoluteString.trimmingCharacters(in: .punctuationCharacters).lastIndex(of: "/") else { return nil }
        startOfName = url.absoluteString.index(startOfName, offsetBy: 1)
        guard let endOfName = url.absoluteString.lastIndex(of: ".") else { return nil }
        let ebookName = url.absoluteString[startOfName..<endOfName]
        return String(ebookName)
        
    }

}

class EBookCell: UITableViewCell {
    
    static let identifier = "EBookCell"
    
    public var url:URL?
    
    public weak var deleteButton:UIButton?
    
    func setup (bookDetails: BookDetails, title: String) {
        self.selectionStyle = .none

        let deleteButton = Style.largeButton(with: "Delete", fontColor: .red)
        
        let bookCard = GRBootstrapElement(color: .white, anchorWidthToScreenWidth: false, margin:
            BootstrapMargin(
                left: 40,
                top: 30,
                right: 40,
                bottom: 30), superview: nil)
        
        let detailsCard = GRBootstrapElement(color: .white, anchorWidthToScreenWidth: false)
            .addRow(columns: [
                Column(cardSet: Style.label(withText: bookDetails.title ?? title, superview: nil, color: .black)
                    .font(CustomFontBook.Medium.of(size: Style.getScreenSize() == .sm ? .medium : .large))
                    .toCardSet(),
                       colWidth: .Twelve),
                Column(cardSet: Style.label(withText: "Written By: \(bookDetails.author ?? "Not Sure")", superview: nil, color: .black)
                    .font(CustomFontBook.Regular.of(size: Style.getScreenSize() == .sm ? .small : .medium))
                    .toCardSet(),
                       colWidth: .Twelve)
            ]).addRow(columns: [
                Column(cardSet: deleteButton
                .radius(radius: 5)
                .backgroundColor(UIColor.EZRemember.lightRed)
                    .toCardSet().withHeight(50), colWidth: Style.getScreenSize() == .sm ? .Four : .Two)
            ], anchorToBottom: true)
        
        let coverImage = UIImageView(image: bookDetails.coverImage)
        coverImage.contentMode = .scaleAspectFit
        
        bookCard.addRow(columns: [
            // Add the image to the left
            Column(cardSet: UIImageView(image: bookDetails.coverImage)
                .backgroundColor(UIColor.EZRemember.lightGreen)
                .toCardSet()
                .withHeight(250),
                   colWidth: Style.getScreenSize() == .sm ? .Three : .Two),
            // Add the book details to the right
            Column(cardSet: detailsCard.toCardSet(), colWidth: Style.getScreenSize() == .sm ? .Nine : .Five),
                        
        ], anchorToBottom: true)
        
        bookCard.addToSuperview(superview: self.contentView, anchorToBottom: true)
        self.deleteButton = deleteButton
    }
    
}
