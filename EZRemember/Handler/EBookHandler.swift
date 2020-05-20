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

public class EBookHandler {
    
    private let kApplicationDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    
    private let disposeBag = DisposeBag()
    
    func backupAllEbooks () {
        let urls = self.getUrls(fromInbox: true)?.filter( {UtilityFunctions.urlIsEpub(url: $0) })
        var uploadEpubObservables = [Observable<String?>]()
        urls?.forEach({ [weak self] (url) in
            guard let self = self else { return }
            guard let epubName = self.getEbookNameFromUrl(url: url) else { return }
            
            let uploadTask = FirebaseStorageManager.shared.uploadData(refPath: "\(UtilityFunctions.deviceId())/epubs/", fileName: "\(epubName).epub", fileUrl: url)
            uploadEpubObservables.append(uploadTask)
        })
        
        self.uploadBooks(uploadEpubObservables: uploadEpubObservables)
    }
    
    public func downloadBooks () {
        
    }
    
    private func uploadBooks (uploadEpubObservables: [Observable<String?>]) {
        Observable.combineLatest(uploadEpubObservables)
        .subscribe { (event) in
            if let elements = event.element, let urls = elements as? [String] {
                SyncManager.shared.backupEpubs(urls: urls).retry(5).subscribe(onCompleted: {
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
    
    public func getEbookNameFromUrl (url: URL) -> String? {
        
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
