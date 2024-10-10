//
//  FolderListItemModel.swift
//  HashCamera
//
//  Created by Anto-Yang on 8/25/24.
//

import Foundation

struct FolderListItemModel {
    
    let type: FolderListItemType
    let url: URL
    var name: String {
        switch type {
        case .unclassified:
            return "Unclassified"
        case .folder:
            return url.lastPathComponent
        }
    }
    
    enum FolderListItemType {
        case unclassified
        case folder
    }

}
