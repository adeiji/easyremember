//
//  ConvertToEpubHandler.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/25/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation

class ConvertToEpubHandler {
    
    public static let shared = ConvertToEpubHandler()
    
    private let kConversionJobs = "conversionJobs"
    
    private var jobProcess = [String:JobState]()
    
    private var timer:Timer?
    
    private enum JobState {
        case Downloading
        case Finished
        case Waiting
    }
    
    private init() {}
    
    // - MARK: Entry Point Methods
    
    public func convertPDFAtUrl (_ url: URL, completion: @escaping (Bool) -> Void) {
        
        #if DEBUG
        guard let convertUrl = URL(string: "https://ezremember.ngrok.io/convertPDF") else { return }
        #else
        guard let convertUrl = URL(string: "https://pdf-conversion.herokuapp.com/convertPDF") else { return }
        #endif
        
        guard let fileToConvert = try? Data(contentsOf: url) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.url = convertUrl
        request.httpBody = fileToConvert
        request.addValue("application/pdf", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else { return }
            guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else { return }
            if let object = json as? [String:Any] {
                if self.createEpubJob(object["jobId"] as? Int, name: object["fileName"] as? String) {
                    completion(true)
                    self.isStillDownloadingEpubs(completion: nil)
                } else {
                    completion(false)
                }
            }
            
        }
        
        task.resume()
    }
    
    /**
     - parameter completion: Returns a boolean value representing whether there are any conversion processes still in queue
     */
    public func isStillDownloadingEpubs (completion: ((Bool) -> Void)?) {
                        
        let jobIds = Array(self.getCurrentConversionJobs().keys)
        
        jobIds.forEach { (key) in
            // Only create a job process for a job id that has not already been created
            if self.jobProcess[key] == nil {
                self.jobProcess[key] = .Waiting
            }
            
        }
        
        if jobIds.count > 0 {
            completion?(true)
        } else {
            completion?(false)
            return
        }
                                
        self.timer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(downloadFinishedEpubs), userInfo: nil, repeats: true)
        
        self.downloadFinishedEpubs()
        
    }
    
    
    @objc private func downloadFinishedEpubs() {
                
        self.jobProcess.keys.forEach { (jobId) in
            // If this job has already been marked finished that means its currently downloading
            if self.jobProcess[jobId] != .Waiting {
                return
            }
            
            self.isJobComplete(jobId) { (finished) in
                if (finished) {
                    self.jobProcess[jobId] = .Downloading
                    self.downloadEpubWithJobId(jobId)
                }
            }
        }
    }
    
    private func isJobComplete (_ jobId: String, completion: @escaping (Bool) -> Void) {
        #if DEBUG
        guard var isCompleteUrl = URLComponents(string: "https://ezremember.ngrok.io/isJobComplete") else { return }
        #else
        guard var isCompleteUrl = URLComponents(string: "https://pdf-conversion.herokuapp.com/isJobComplete") else { return }
        #endif
        isCompleteUrl.queryItems = [
            URLQueryItem(name: "jobId", value: jobId)
        ]
            
        let request = URLRequest(url: isCompleteUrl.url!)

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else { return }
            guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else { return }
            if let object = json as? [String:Bool] {
                if (object["finished"] == true) {
                    completion(true)
                }
            } else {
                completion(false)
            }
        }
        
        task.resume()
    }
    
    
    private func downloadEpubWithJobId (_ jobId: String) {
        #if DEBUG
        guard var downloadUrl = URLComponents(string: "https://ezremember.ngrok.io/downloadEpub") else { return }
        #else
        guard var downloadUrl = URLComponents(string: "https://pdf-conversion.herokuapp.com/downloadEpub") else { return }
        #endif
        downloadUrl.queryItems = [
            URLQueryItem(name: "jobId", value: jobId)
        ]
        
        let request = URLRequest(url: downloadUrl.url!)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else { return }
            let ebookHandler = BookHandler()
            let bookName = self.epubNameForJobId(jobId) ?? "\(UUID().uuidString).epub"
            if ebookHandler.saveEpubDataWithName(data, bookName: bookName) {
                self.jobProcess[jobId] = .Finished
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .FinishedConvertingPDF, object: nil, userInfo: [ "bookName": bookName ])
                }
            }
            
            self.finishedJobWithId(jobId)
        }
        
        task.resume()
    }
    
    private func createEpubJob (_ jobId: Int?, name: String?) -> Bool {
        guard
            let jobId = jobId,
            let name = name else
        { return false }
                        
        var conversionJobs = UserDefaults.standard.object(forKey: self.kConversionJobs) as? [String:Any] ?? [String:Any]()
        conversionJobs["\(jobId)"] = name.replacingOccurrences(of: ".pdf", with: ".epub")
        UserDefaults.standard.set(conversionJobs, forKey: self.kConversionJobs)
        UserDefaults.standard.synchronize()
        return true
    }
    
    private func getCurrentConversionJobs () -> [String:Any] {
        return UserDefaults.standard.object(forKey: self.kConversionJobs) as? [String:Any] ?? [String:Any]()
    }
    
    private func epubNameForJobId (_ jobId: String) -> String? {
        let conversionJobs = UserDefaults.standard.object(forKey: self.kConversionJobs) as? [String:Any] ?? [String:Any]()
        return conversionJobs[jobId] as? String
    }
    
    private func finishedJobWithId (_ jobId: String) {
        var conversionJobs = UserDefaults.standard.object(forKey: self.kConversionJobs) as? [String:Any] ?? [String:Any]()
        conversionJobs[jobId] = nil
        UserDefaults.standard.set(conversionJobs, forKey: self.kConversionJobs)
        UserDefaults.standard.synchronize()
    }
    
}
