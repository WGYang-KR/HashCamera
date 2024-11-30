//
//  WidgetSetting.swift
//  HashCamera
//
//  Created by Anto-Yang on 11/30/24.
//

import Foundation

class WidgetSetting {
    
    enum Keys: String {
        case widgetFolderList
    }
    
    static var folderList: [FolderModel] {
        get {
            return UserDefaults.shared.getObject(forKey: Keys.widgetFolderList.rawValue, objectType: [FolderModel].self) ?? []
        }
        set {
            UserDefaults.shared.setObject(newValue, forKey: Keys.widgetFolderList.rawValue)
        }
    }

}

extension UserDefaults {
    ///AppGroup에서 공유되는 UserDefaults
    static var shared: UserDefaults {
        // ✅ App Groups Identifier 를 저장하는 변수
        let appGroupID = "group.wgyang.hashcamera"
        
        // ✅ 파라미터로 전달되는 이름의 기본값으로 초기화된 UserDefaults 개체를 만든다.
        // ✅ 이전까지 사용했던 standard UserDefaults 와 다르다. 공유되는 App Group Container 에 있는 저장소를 사용한다.
        // ✅ suitename : The domain identifier of the search list.
        return UserDefaults(suiteName: appGroupID)!
    }
}
