//
//  EBookHandler.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/11/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import SSZipArchive
import RxSwift
import SwiftyBootstrap
import DephynedFire
import FolioReaderKit


public class BookHandler {
        
    private let kTempFolder = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/temp"
    private let kBooksFolder = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/Books"
    private let kPDFFolder = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/PDF"
    private let kInboxFolder = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/Inbox"
    private let disposeBag = DisposeBag()
    
    func backupEbooksAtUrls (urls: [URL]? = nil) {
        let urls = urls != nil ? urls : self.getUrls(fromInbox: true)?.filter( {UtilityFunctions.urlIsEpub(url: $0) || $0.pathExtension.lowercased() == "pdf" })
        var uploadEpubObservables = [Observable<(fileName: String?, url: URL?)>]()
        urls?.forEach({ [weak self] (url) in
            guard let self = self else { return }
            guard let epubName = self.getEbookNameFromUrl(url: url) else { return }
            
            let uploadTask = FirebaseStorageManager.shared.uploadData(refPath: "\(UtilityFunctions.deviceId())/epubs/", fileName: "\(epubName).\(url.pathExtension.lowercased())", fileUrl: url)
            uploadEpubObservables.append(uploadTask)
        })
        
        self.uploadBooks(uploadEpubObservables: uploadEpubObservables)
    }
    
    /**
     When we download a book it saves the compressed epub to the /temp sub-directory of our Application Directory, we need to then unzip this epub and store it in the Application Directory and then delete it from the /temp directory
     */
    private func unzipBookAtUrl (url: URL) {
        do {
            let _ = try FREpubParser().readEpub(epubPath: url.path, removeEpub: true, unzipPath: self.kBooksFolder)
        } catch {
            AnalyticsManager.logError(message: error.localizedDescription)
        }
    }
    
    @discardableResult func saveEpubDataWithName (_ data: Data, bookName: String) -> Bool {
        let saveToUrl = URL(fileURLWithPath: "\(self.kTempFolder)/\(bookName)")
        do {
            try data.write(to: saveToUrl)
            self.unzipBookAtUrl(url: saveToUrl)
            return true
        } catch {
            print(error.localizedDescription)
            AnalyticsManager.logError(message: error.localizedDescription)
            return false
        }
    }
    
    func downloadBooks (sync: Sync) {
        
        var downloadTasks = [Completable]()
        var bookUrls = [URL]()
        
        sync.books?.forEach({ (bookName) in
            // Where we're going to save the book to
            let saveToUrl = URL(fileURLWithPath: "\(self.kTempFolder)/\(bookName)")
            let downloadTask = FirebaseStorageManager.shared.downloadData(refPath: "\(sync.deviceId)/epubs/\(bookName)", saveToUrl: saveToUrl)
            downloadTasks.append(downloadTask)
            bookUrls.append(saveToUrl)
        })
        
        self.executeDownloadTasks(downloadTasks: downloadTasks, bookUrls: bookUrls)
    }
    
    /**
     Download all the ePubs from the server and then unzip them
     */
    private func executeDownloadTasks (downloadTasks: [Completable], bookUrls:[URL]) {
        Completable.zip(downloadTasks).subscribe(onCompleted: {
            NotificationCenter.default.post(name: .FinishedDownloadingBooks, object: nil)
            bookUrls.forEach { (bookUrl) in
                self.unzipBookAtUrl(url: bookUrl)
            }
            
        }) { (error) in
            print(error.localizedDescription)
            AnalyticsManager.logError(message: error.localizedDescription)
            NotificationCenter.default.post(name: .ErrorDownloadingBooks, object: nil, userInfo: ["error": error.localizedDescription])
        }.disposed(by: self.disposeBag)
    }
    
    private func uploadBooks (uploadEpubObservables: [Observable<(fileName: String?, url: URL?)>]) {
        Observable.combineLatest(uploadEpubObservables)
        .subscribe { (event) in
            if let elements = event.element {
                let filenames = elements.compactMap( { $0.fileName } )
                
                SyncManager.shared.backupEpubs(filenames: filenames).retry(5).subscribe(onCompleted: {
                    NotificationCenter.default.post(name: .SyncingFinished, object: nil)
                }) { (error) in
                    AnalyticsManager.logError(message: error.localizedDescription)
                    NotificationCenter.default.post(name: .SyncingError, object: nil)
                }.disposed(by: self.disposeBag)
            }
        }.disposed(by: self.disposeBag)
    }
    
    func getUrlsWithExtension (_ extensionType: String, searchFolder: URL?) -> [URL]? {
        
        guard let searchFolder = searchFolder else { return nil }
        
        do {
            var booksInAppDirUrls = try FileManager().contentsOfDirectory(at: searchFolder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                        
            booksInAppDirUrls = self.removeURLsNotOfType(extensionType, urls: booksInAppDirUrls)
            booksInAppDirUrls.sort(by: { $0.absoluteString > $1.absoluteString })
            return booksInAppDirUrls
        } catch {
            print(error.localizedDescription)
        }

        return nil
    }
    
    /**
     Get the URL for every single book that is within this application wether PDF or ebook
     */
    func getUrls (fromInbox: Bool = false) -> [URL]? {

        var urls = self.getUrlsWithExtension("epub", searchFolder: URL(string: self.kBooksFolder))
        if let pdfUrls = self.getUrlsWithExtension("pdf", searchFolder: URL(fileURLWithPath: self.kBooksFolder)) {
            urls?.append(contentsOf: pdfUrls)
        }
        
        return urls
    }
    
    // MARK: Remove All Non Epub Files
    
    private func removeURLsNotOfType (_ type: String, urls: [URL]) -> [URL] {
        
        return urls.filter { (url) -> Bool in
            guard var startOfFileEnding = url.absoluteString.lastIndex(of: ".") else { return false }
            startOfFileEnding = url.absoluteString.index(startOfFileEnding, offsetBy: 1)
            
            let fileEnding = url.absoluteString[startOfFileEnding...]
            if fileEnding.lowercased().contains(type) == false {
                return false
            }
            
            return true
        }
                        
    }
    
    public func getURLForBookNamed (_ bookName: String) -> String {
        if bookName.contains(".epub") {
            return "\(self.kBooksFolder)/\(bookName)"
        } else {
            return "\(self.kBooksFolder)/\(bookName).epub"
        }        
    }
    
    public func getEbookNameFromUrl (url: URL?) -> String? {
        guard let url = url else { return nil }
        guard var startOfName = url.absoluteString.trimmingCharacters(in: .punctuationCharacters).lastIndex(of: "/") else { return nil }
        startOfName = url.absoluteString.index(startOfName, offsetBy: 1)
        guard let endOfName = url.absoluteString.lastIndex(of: ".") else { return nil }
        let ebookName = url.absoluteString[startOfName..<endOfName]
        return String(ebookName).replacingOccurrences(of: "%20", with: " ")
    }
    
    // - MARK: Get Book Information
    
    public func getReader (url: URL, folioReader: FolioReader, parentVC: UIViewController) -> FolioReaderContainer {
        let config = FolioReaderConfig()
        config.displayTitle = true
        let reader = folioReader.getReader(parentViewController: parentVC, withEpubPath: url.path, unzipPath: self.kBooksFolder, andConfig: config, shouldRemoveEpub: false)
        return reader
    }
    
    public func getTitleFromBookPath (_ path: String) -> String? {
        let title = try? FolioReader.getTitle(path, unzipPath: self.kBooksFolder)
        return title
    }
    
    public func getCoverImageFromBookPath (_ path: String) -> UIImage? {
        let coverImage = try? FolioReader.getCoverImage(path, unzipPath: self.kBooksFolder)
        return coverImage
    }
    
    public func getAuthorFromBookPath (_ path: String) -> String? {
        let authorName = try? FolioReader.getAuthorName(path, unzipPath: self.kBooksFolder)
        return authorName
    }
    
    @discardableResult public func movePDFsToPDFFolder (customPDFUrls: [URL]? = nil) -> [URL]? {
        let pdfFolder = URL(fileURLWithPath: self.kBooksFolder)
        
        var pdfUrls = customPDFUrls
        
        if pdfUrls == nil {
            pdfUrls = self.getUrlsWithExtension("pdf", searchFolder: Bundle.main.resourceURL)
        }
        
        var movedToUrls = [URL]()
        
        let fileManager = FileManager.default
        pdfUrls?.forEach({ (pdfUrl) in
            do {
                if fileManager.fileExists(atPath: pdfFolder.path) == false {
                    try fileManager.createDirectory(atPath: pdfFolder.path, withIntermediateDirectories: false, attributes: nil)
                }
                guard let moveToUrl = URL(string: "\(pdfFolder)\(pdfUrl.lastPathComponent)") else { return }
                try fileManager.moveItem(at: pdfUrl, to: moveToUrl )
                movedToUrls.append(moveToUrl)
            } catch {
                print(error.localizedDescription)
                AnalyticsManager.logError(message: error.localizedDescription)
            }
        })
        
        return movedToUrls
    }
    
    public func prepareBooks () {
        self.unzipEpubs()
        self.movePDFsToPDFFolder()
    }
        
    /**
     All the ePubs that are originally in this application ie, the application folder, we want to unzip them and put them in the Books folder so that the user can read them, but more specifically so that the user can delete them from the Books folder and not have to view the books within the app anymore
     */
    private func unzipEpubs () {
        
        // Make sure that you don't change this string value.  Read the documentation for isFirstTime function for more details
        if UtilityFunctions.isFirstTime("Unzipping the ePubs in the application directory") == false {
            return
        }
        
        guard let resourceURL = Bundle.main.resourceURL else { return  }
        guard var urls = try? FileManager().contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else { return }
        guard let booksDirUrl = URL(string: self.kBooksFolder) else { return }
        
        urls = self.removeURLsNotOfType("epub", urls: urls)
        urls.forEach({ (url) in
            guard let epubName = self.getEbookNameFromUrl(url: url) else { return }
            SSZipArchive.unzipFile(atPath: url.path, toDestination: "\(booksDirUrl.path)/\(epubName).epub", delegate: nil)
        })
    }
    
}
