//
//  GRNetworking.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/7/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import RxSwift
import DephynedFire

typealias ResponseObject = FirebaseDocument

class GRNetworking {
    
    class func executeRequest<T: Codable>(urlString: String, body: [String:String]) -> Observable<[T]> {
        guard let url = URL(string: urlString) else { return .empty() }
        
        return Observable<[T]>.create { (observer) -> Disposable in
            let jsonData = try? JSONSerialization.data(withJSONObject: body)
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            let session = URLSession.shared
                        
            let task = session.dataTask(with: request) { (data, response, error) in
                // Serialize the data into an object
                do {
                    let json = try JSONDecoder().decode([T].self, from: data! )
                    observer.onNext(json)
                } catch {
                    observer.onError(error)
                }
            }
            
            task.resume()
            return Disposables.create()
        }
    }
}
