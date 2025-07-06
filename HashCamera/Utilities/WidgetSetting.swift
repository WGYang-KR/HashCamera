//
//  WidgetSetting.swift
//  HashCamera
//
//  Created by Anto-Yang on 12/4/24.
//
import Foundation
import WidgetKit

class WidgetSetting {
    
    static let shortcutWidgetID = "com.hashcamera.shortcutWidge"
    enum Keys: String {
        case widgetFolderList
    }
    ///UserDefaults에 저장되어 있는 폴더 목록
    static var folderList: [any FolderModelProtocol] {
        get {
            if let data = UserDefaults.standard.data(forKey: Keys.widgetFolderList.rawValue),
               let wrapper = try? JSONDecoder().decode([FolderModelWrapper].self, from: data) {
                return wrapper.map { $0.base }
            }
            return []
        }
        set {
            let wrapped: [FolderModelWrapper] = newValue.compactMap { item in
                if let folder = item as? LocalFolderModel {
                    return .local(folder)
                } else if let folder = item as? GoogleDriveFolderModel {
                    return .google(folder)
                } else {
                    return nil
                }
            }
            
            if let encoded = try? JSONEncoder().encode(wrapped) {
                UserDefaults.standard.set(encoded, forKey: Keys.widgetFolderList.rawValue)
            }
            
            WidgetCenter.shared.reloadTimelines(ofKind: Self.shortcutWidgetID)
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
