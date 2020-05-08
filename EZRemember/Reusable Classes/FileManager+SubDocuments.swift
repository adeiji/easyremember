//
//  FileManager+SubDocuments.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/8/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation

public extension FileManager {
    
    func urls(for DocumentsDirectory: String) -> [URL]? {
        let dirs = urls(for: .documentDirectory, in: .userDomainMask)
            //this will give you the path to MyFiles
        let MyFilesPath = dirs[0].appendingPathComponent(DocumentsDirectory)
        
        let fileList = try? contentsOfDirectory(at: MyFilesPath, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        return fileList
    }
    
}
