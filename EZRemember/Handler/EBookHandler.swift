//
//  EBookHandler.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/11/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import SSZipArchive

public class EBookHandler {
    
    private let kApplicationDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    
    func getUrls () -> [URL]? {
        guard let resourceURL = Bundle.main.resourceURL else { return nil }
        guard let applicationDirUrl = URL(string: self.kApplicationDirectory) else { return nil }
        
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
