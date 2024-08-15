//
//  BrowserVM.swift
//  HashCamera
//
//  Created by Anto-Yang on 7/18/24.
//

import UIKit
import QuickLookThumbnailing

class ImageFileModel {

    
    let url: URL
    var thumbnailRequest: QLThumbnailGenerator.Request?
    var lowThumbnailImage: UIImage?
    var highThumbnailImage: UIImage?
    var originalImage: UIImage?
    
    
    init(url: URL, 
         thumbnailRequest: QLThumbnailGenerator.Request? = nil,
         lowThumbnailImage: UIImage? = nil,
         highThumbnailImage: UIImage? = nil, 
         originalImage: UIImage? = nil) {
        
        self.url = url
        self.thumbnailRequest = thumbnailRequest
        self.lowThumbnailImage = lowThumbnailImage
        self.highThumbnailImage = highThumbnailImage
        self.originalImage = originalImage
    }
}

class BrowserVM {
    
    
    
}
