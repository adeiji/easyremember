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

public class DEEpubReaderController: UIViewController, FolioReaderPageDelegate, FolioReaderCenterDelegate {
    
    open var currentPage:FolioReaderPage?
    
    open weak var translateWord:UIButton?
    
    public var wordToTranslate:String?
    
    public var disposeBag:DisposeBag = DisposeBag()
    
    weak var mainView:GRViewWithTableView?
    
    private var urlRelay = BehaviorRelay<[URL]>(value: [])
    
    private var ebookUrl:URL?
    
    private let kApplicationDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    
    init(ebookUrl: URL? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.ebookUrl = ebookUrl
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let urls = self.getUrls() else { return }
        self.urlRelay.accept(urls)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
                        
        if let ebookUrl = self.ebookUrl {
            self.showBookReader(url: ebookUrl)
        }
                
        self.mainView = GRViewWithTableView().setup(withSuperview: self.view, header: "Your Books", rightNavBarButtonTitle: "")
        self.mainView?.tableView.register(EBookCell.self, forCellReuseIdentifier: EBookCell.identifier)
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
            guard let booksInInbox = FileManager().urls(for: "/Inbox") else { return nil }
            let booksInAppDirUrls = try FileManager().contentsOfDirectory(at: applicationDirUrl, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            urls.append(contentsOf: booksInAppDirUrls)
            urls.append(contentsOf: booksInInbox)
            urls = self.removeAllNonEpubFiles(urls: urls)
            return urls
        } catch {
            
        }

        return nil
    }
    
    private func showBookReader (url: URL?) {
        
        guard let url = url else { return }
        
        var bookPath = Bundle.main.path(forResource: self.getEbookNameFromUrl(url: url), ofType: "epub")
        
        if bookPath == nil {
            bookPath = url.absoluteString.replacingOccurrences(of: "file:", with: "")
        }
        
        let config = FolioReaderConfig()
        config.displayTitle = true
        
        let folioReader = FolioReader()
        
        guard let unwrappedBookPath = bookPath else { return }
        
        folioReader.presentReader(parentViewController: self, withEpubPath: unwrappedBookPath, andConfig: config)
        folioReader.readerCenter?.pageDelegate = self
        folioReader.readerCenter?.delegate = self
    }
    
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
    /// TODO: Rename this
    public func showEBooks () {
                
        guard let tableView = self.mainView?.tableView else { return }
        
        self.urlRelay
        .bind(to:
            tableView
            .rx
            .items(cellIdentifier: EBookCell.identifier, cellType: EBookCell.self)) { (row, url, cell) in
                cell.textLabel?.text = self.getEbookNameFromUrl(url: url)
                cell.textLabel?.font = CustomFontBook.Black.of(size: .medium)
                cell.url = url
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
    
    public func pageTap(_ recognizer: UITapGestureRecognizer) {
        self.translateWord?.removeFromSuperview()
        self.translateWord = nil
    }
    
    @objc public func createMenuCalled (_ notification: Notification) {
        
        
        guard let presentedViewController = self.presentedViewController else { return }
        guard let word = notification.userInfo?["SelectedText"] as? String else { return }
        self.wordToTranslate = word
        
        if self.translateWord != nil {
            return
        }
        
        let translateButton = Style.largeButton(with: "Translate", backgroundColor: UIColor.EZRemember.lightGreen, fontColor: .darkGray)
        translateButton.titleLabel?.font = CustomFontBook.Medium.of(size: .small)
        translateButton.showsTouchWhenHighlighted = true
        translateButton.radius(radius: 20.0)
        
        presentedViewController.view.addSubview(translateButton)
        translateButton.snp.makeConstraints { (make) in
            make.bottom.equalTo(presentedViewController.view).offset(-10)
            make.centerX.equalTo(presentedViewController.view)
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
                    let showTranslationsViewController = DEShowTranslationsViewController(translations: translations, originalWord: wordToTranslate)
                    presentedViewController.present(showTranslationsViewController, animated: true, completion: nil)
                }
            }.disposed(by: self.disposeBag)
        }
        
        self.translateWord = translateButton
    }
    
    
    
    public func pageDidAppear(_ page: FolioReaderPage) {
        self.currentPage = page
    }
    
}

class EBookCell: UITableViewCell {
    
    static let identifier = "EBookCell"
    
    public var url:URL?
    
}
