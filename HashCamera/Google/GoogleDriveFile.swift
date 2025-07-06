//
//  GoogleDriveFileModel.swift
//  HashCamera
//
//  Created by Anto-Yang on 6/22/25.
//
import Foundation

struct GoogleDriveFile: Codable, Hashable {
    let id: String
    let name: String
    let mimeType: String
    let thumbnailURL: String
    let downloadURL: String

    var isImage: Bool {
        return mimeType.contains("image/")
    }

    var isVideo: Bool {
        return mimeType.contains("video/")
    }
    
    var isFolder: Bool {
        return mimeType == "application/vnd.google-apps.folder"
    }
    

}
