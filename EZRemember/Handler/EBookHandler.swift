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

public class EBookHandler {
    
    private let kApplicationDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    
    private let disposeBag = DisposeBag()
    
    func backupEbooksAtUrls (urls: [URL]? = nil) {
        let urls = urls != nil ? urls : self.getUrls(fromInbox: true)?.filter( {UtilityFunctions.urlIsEpub(url: $0) })
        var uploadEpubObservables = [Observable<(fileName: String?, url: URL?)>]()
        urls?.forEach({ [weak self] (url) in
            guard let self = self else { return }
            guard let epubName = self.getEbookNameFromUrl(url: url) else { return }
            
            let uploadTask = FirebaseStorageManager.shared.uploadData(refPath: "\(UtilityFunctions.deviceId())/epubs/", fileName: "\(epubName).epub", fileUrl: url)
            uploadEpubObservables.append(uploadTask)
        })
        
        self.uploadBooks(uploadEpubObservables: uploadEpubObservables)
    }
    
    /**
     When we download a book it saves the compressed epub to the /temp sub-directory of our Application Directory, we need to then unzip this epub and store it in the Application Directory and then delete it from the /temp directory
     */
    private func unzipBookAtUrl (url: URL) {
        do {
            let _ = try FREpubParser().readEpub(epubPath: url.path, removeEpub: true, unzipPath: nil)
        } catch {
            AnalyticsManager.logError(message: error.localizedDescription)
        }
    }
    
    func downloadBooks (sync: Sync) {
        
        var downloadTasks = [Completable]()
        var bookUrls = [URL]()
        
        sync.books?.forEach({ (bookName) in
            // Where we're going to save the book to
            let saveToUrl = URL(fileURLWithPath: "\(self.kApplicationDirectory)/temp/\(bookName)")
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
    
    func getUrls (fromInbox: Bool = false) -> [URL]? {
        let directoryToGetEbooksFrom = fromInbox ? "\(self.kApplicationDirectory)/Inbox" : self.kApplicationDirectory
        guard let applicationDirUrl = URL(string: directoryToGetEbooksFrom) else { return nil }
        
        do {
            var booksInAppDirUrls = try FileManager().contentsOfDirectory(at: applicationDirUrl, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                        
            booksInAppDirUrls = self.removeAllNonEpubFiles(urls: booksInAppDirUrls)
            booksInAppDirUrls.sort(by: { $0.absoluteString > $1.absoluteString })
            return booksInAppDirUrls
        } catch {
            print(error.localizedDescription)
        }

        return nil
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
    
    public func getEbookNameFromUrl (url: URL?) -> String? {
        guard let url = url else { return nil }
        guard var startOfName = url.absoluteString.trimmingCharacters(in: .punctuationCharacters).lastIndex(of: "/") else { return nil }
        startOfName = url.absoluteString.index(startOfName, offsetBy: 1)
        guard let endOfName = url.absoluteString.lastIndex(of: ".") else { return nil }
        let ebookName = url.absoluteString[startOfName..<endOfName]
        return String(ebookName).replacingOccurrences(of: "%20", with: " ")
        
    }
    
    public func unzipEpubs () {
        guard let resourceURL = Bundle.main.resourceURL else { return  }
        guard var urls = try? FileManager().contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else { return }
        guard let applicationDirUrl = URL(string: self.kApplicationDirectory) else { return }
        
        urls = self.removeAllNonEpubFiles(urls: urls)
        urls.forEach({ (url) in
            guard let epubName = self.getEbookNameFromUrl(url: url) else { return }
            SSZipArchive.unzipFile(atPath: url.path, toDestination: "\(applicationDirUrl.path)/\(epubName).epub", delegate: nil)
        })
        
    }
    
}
