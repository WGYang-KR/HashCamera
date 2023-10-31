//
//  StorageType.swift
//  HashCamera
//
//  Created by WG-Yang on 10/24/23.
//

import Foundation

enum StorageType: Codable{
    case photoLibrary, iCloudDrive, localDrive
    
    var simpleString: String {
        switch self {
        case .photoLibrary:
            return "Library"
        case .iCloudDrive:
            return "iCloud"
        case .localDrive:
            return "Local Folder"
        }
    }
}
