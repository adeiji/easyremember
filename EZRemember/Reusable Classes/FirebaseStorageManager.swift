//
//  FirebaseStorageManager.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/20/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation
import FirebaseStorage
import RxSwift

class FirebaseStorageManager {
    
    static let shared = FirebaseStorageManager()
    
    enum StorageError:Error {
        case NoMetadata
    }
    
    func downloadData (refPath: String, saveToUrl:URL) -> Completable {
        let storageRef = Storage.storage().reference(withPath: refPath)
        return Completable.create { completable in
            storageRef.write(toFile: saveToUrl) { (url, error) in
                if let error = error {
                    completable(.error(error))
                    return
                }
                
                completable(.completed)
            }
            
            return Disposables.create ()
        }
        
    }
    
    /**
     - parameters:
        - refPath: The foldername
        - fileName: call this file what?
        - filepath: The local file path of this file
     */
    func uploadData (refPath: String, fileName: String, fileUrl: URL) -> Observable<(fileName: String?, url: URL?)> {
        let storageRef = Storage.storage().reference(withPath: "\(refPath)/\(fileName)")
        
        guard let fileData = try? Data(contentsOf: fileUrl) else {
            return .empty()
        }
        
        return Observable.create { (observable) -> Disposable in
            storageRef.putData(fileData, metadata: nil) { (metadata, error) in
                if let error = error {
                    observable.onError(error)
                    observable.onCompleted()
                }
                else {
                    storageRef.downloadURL { (url, error) in
                        if let error = error {
                            observable.onError(error)
                            observable.onCompleted()
                        } else {
                            observable.onNext((fileName: fileName, url: url))
                            observable.onCompleted()
                        }
                    }
                }
            }
            
            return Disposables.create()
        }
    }
}
