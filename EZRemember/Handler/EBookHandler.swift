//
//  EBookHandler.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/11/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation

public class EBookHandler {
    
    private let kApplicationDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    
    func getUrls () -> [URL]? {
        guard let resourceURL = Bundle.main.resourceURL else { return nil }
        guard let applicationDirUrl = URL(string: self.kApplicationDirectory) else { return nil }
        
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
        return String(ebookName)
        
    }
    
}
