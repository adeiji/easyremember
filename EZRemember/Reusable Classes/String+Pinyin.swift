//
//  String+Pinyin.swift
//  EZRemember
//
//  Created by Adebayo Ijidakinro on 5/7/20.
//  Copyright © 2020 Dephyned. All rights reserved.
//

import Foundation

public extension String {
    
    public func isIncludeChinese() -> Bool {
        for ch in self.unicodeScalars {
                         // Chinese character range: 0x4e00 ~ 0x9fff
            if (0x4e00 < ch.value  && ch.value < 0x9fff) {
                return true
            }
        }
        return false
    }
    

    func transformToPinyin() -> String {
        let stringRef = NSMutableString(string: self) as CFMutableString
        CFStringTransform(stringRef,nil, kCFStringTransformToLatin, false);
        let pinyin = stringRef as String;
     
        return pinyin
    }
    
    func transformToPinyinWithoutBlank() -> String {
        var pinyin = self.transformToPinyin()
        // remove the space
        pinyin = pinyin.replacingOccurrences(of: " ", with: "")
        return pinyin
    }
}
