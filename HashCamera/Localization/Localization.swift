//
// Localization.swift
//  HashCamera
//
//  Created by Anto-Yang on 11/14/24.
//
import Foundation
import UIKit

func localizedString(forKey key: String, value: String?) -> String  {
    if Localization.bundle == nil {
        Localization.setLanguage()
    }
    return Localization.localizedString(forKey: key, value: value)
}

class Localization {
    
    static var bundle: Bundle?

    ///bundle을 초기화한다
    static func setLanguage() {
        //저장된 언어 설정을 가져옴
        var language = UserDefaults.standard.array(forKey: "language")?.first as? String
        if language == nil {
            //설정된 언어 없으면 기기 언어 설정을 가져옴
            let str = Locale.preferredLanguages.first ?? "en"   // 언어코드-지역코드 (ex. ko-KR, en-US)
            language = String(str.dropLast(3))                  // ko-KR => ko, en-US => en
        }
        
        // 해당 언어 파일 가져오기. 기본값 en
        let path = Bundle.main.path(forResource: language, ofType: "lproj") ?? Bundle.main.path(forResource: "en", ofType: "lproj")
        bundle = Bundle(path: path!)
    }
    
    static func localizedString(forKey key: String, value: String?) -> String {
        return bundle?.localizedString(forKey: key, value: value, table: nil) ?? value ?? key
    }
    
}
