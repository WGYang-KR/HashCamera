//
//  ImageFileModel.swift
//  HashCamera
//
//  Created by Anto-Yang on 9/15/24.
//

import Foundation
import QuickLookThumbnailing

class ImageFileModel {
    
    let url: URL
    var thumbnailRequest: QLThumbnailGenerator.Request?
    
    init(url: URL,
         thumbnailRequest: QLThumbnailGenerator.Request? = nil) {
        
        self.url = url
        self.thumbnailRequest = thumbnailRequest
    }
}
