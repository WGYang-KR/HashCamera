//
//  MediaFileModel.swift
//  HashCamera
//
//  Created by Anto-Yang on 3/28/24.
//

import UIKit
import QuickLookThumbnailing

class MediaFileModel {
    init(url: URL, thumbnailRequest: QLThumbnailGenerator.Request? = nil, lowThumbnailImage: UIImage? = nil, highThumbnailImage: UIImage? = nil, originalImage: UIImage? = nil) {
        self.url = url
        self.thumbnailRequest = thumbnailRequest
        self.lowThumbnailImage = lowThumbnailImage
        self.highThumbnailImage = highThumbnailImage
        self.originalImage = originalImage
    }
    
    let url: URL
    var thumbnailRequest: QLThumbnailGenerator.Request?
    var lowThumbnailImage: UIImage?
    var highThumbnailImage: UIImage?
    var originalImage: UIImage?
    
    func bestImage(completion: @escaping (UIImage?) -> Void) {
        if let bestImage = originalImage { //이미 로드되었으면 바로 반환
            completion(bestImage)
        } else { //없으면 로드후 반환
            HCFileManager.shared.fetchBestImage(url: url) { [weak self] image in
                self?.originalImage = image
                completion(image)
            }
        }
    }
    
}
