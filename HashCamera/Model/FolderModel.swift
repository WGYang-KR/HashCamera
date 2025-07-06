//
//  FolderModel.swift
//  HashCamera
//
//  Created by Anto-Yang on 6/25/25.
//
import Foundation

protocol FolderModelProtocol: Hashable, Codable {
    var type: FolderType { get }
    var name: String { get }

    func isSame(as other: any FolderModelProtocol) -> Bool
}


enum FolderType: Codable {
    case defaultFolder
    case localFolder
    case googleDrive
}

struct DefaultFolderModel: FolderModelProtocol {
    var type: FolderType = .defaultFolder
    
    var url: URL {
        return Utils.documentsFolderURL
    }
    
    var name: String {
        return localizedString(forKey: "N003_2", value: "Default Folder")
    }
    
    func isSame(as other: any FolderModelProtocol) -> Bool {
        return ((other as? DefaultFolderModel) != nil)
    }
}

struct LocalFolderModel: FolderModelProtocol {
    var type: FolderType = .localFolder
    let url: URL
    
    var name: String {
        url.lastPathComponent
    }
    
    func isSame(as other: any FolderModelProtocol) -> Bool {
        guard let other = other as? LocalFolderModel else { return false }
        
        guard let lhsIndex = self.url.pathComponents.firstIndex(of: "Documents"),
              let rhsIndex = other.url.pathComponents.firstIndex(of: "Documents") else {
            return false
        }
        
        // "Documents" 이후의 경로만 비교
        let lhsRelativePath = self.url.pathComponents[lhsIndex...]
        let rhsRelativePath = other.url.pathComponents[rhsIndex...]
        return lhsRelativePath == rhsRelativePath
    }
    
}


struct GoogleDriveFolderModel: FolderModelProtocol {
    var type: FolderType = .googleDrive
    let googleDriveFile: GoogleDriveFile
    
    var name: String {
        googleDriveFile.name
    }
    
    func isSame(as other: any FolderModelProtocol) -> Bool {
        guard let other = other as? GoogleDriveFolderModel else { return false }
        return self.googleDriveFile.id == other.googleDriveFile.id
    }
}



