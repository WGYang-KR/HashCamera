//
//  FolderListItemModel.swift
//  HashCamera
//
//  Created by Anto-Yang on 8/25/24.
//

import Foundation

struct FolderModel: Codable {
    
    let type: FolderType
    let url: URL
    
    var name: String {
        switch type {
        case .defaultFolder:
            return "Default Folder"
        case .folder:
            return url.lastPathComponent
        }
    }
    
    enum FolderType: Int, Codable {
        case defaultFolder
        case folder
    }

}
