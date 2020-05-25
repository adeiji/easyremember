//
//  ConvertToEpubHandler.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/25/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation

class ConvertToEpubHandler {
    
    public func convertPDFAtUrl (_ url: URL) {
        
        guard let convertUrl = URL(string: "https://ezremember.ngrok.io/convertPDF") else { return }
        guard let fileToConvert = try? Data(contentsOf: url) else { return }
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
                        
        request.url = convertUrl
        request.httpBody = fileToConvert
        request.addValue("application/pdf", forHTTPHeaderField: "Content-Type")
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            print(response)
        }
        
        task.resume()
    }
    
    public func downloadConvertedEPUB (jobId: String) {
        
        guard var downloadUrl = URLComponents(string: "https://ezremember.ngrok.io/downloadEpub") else { return }
        
        downloadUrl.queryItems = [
            URLQueryItem(name: "jobId", value: jobId)
        ]
        
        let request = URLRequest(url: downloadUrl.url!)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                
                return
            }
            
            let ebookHandler = EBookHandler()
            ebookHandler.saveEpubDataWithName(data, bookName: self.epubNameForJobId(jobId) ?? "No_Name.epub")
        }
        
        task.resume()
    }
    
    private func epubNameForJobId (_ jobId: String) -> String? {
        return UserDefaults.standard.object(forKey: jobId) as? String
    }
    
}
