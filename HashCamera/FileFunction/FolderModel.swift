//
//  FolderListItemModel.swift
//  HashCamera
//
//  Created by Anto-Yang on 8/25/24.
//

import Foundation

struct FolderModel: Codable, Hashable {
    
    let type: FolderType
    let url: URL
    
    var name: String {
        switch type {
        case .defaultFolder:
            return localizedString(forKey: "N003_2", value: "Default Folder")
        case .folder:
            return url.lastPathComponent
        }
    }
    
    enum FolderType: Int, Codable {
        case defaultFolder
        case folder
    }
    
    // Hashable 프로토콜 준수
      func hash(into hasher: inout Hasher) {
          // 객체를 고유하게 식별할 수 있는 속성으로 해시값을 생성
          hasher.combine(url) // 고유한 식별자로 url를 사용
      }
      
      // `==` 연산자 구현
      static func == (lhs: FolderModel, rhs: FolderModel) -> Bool {
          return lhs.url == rhs.url
      }

}
