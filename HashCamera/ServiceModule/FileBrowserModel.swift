//
//  FileBrowserModel.swift
//  HashCamera
//
//  Created by WG-MacHome on 12/2/23.
//

import UIKit
import QuickLookThumbnailing

class FileBrowserModel {
    
    var storageType: StorageType
    var rootURL: URL?
    var fileList: [FileBrowserItemModel] = []
    let hcFileManager = HCFileManager()
    var thumbnailSize: CGSize
    let qlThumbnailGenerator =  QLThumbnailGenerator.shared
    
    init(storageType: StorageType) {
        self.storageType = storageType
        self.thumbnailSize = CGSize.zero
        switch storageType {
        case .iCloudDrive:
            self.rootURL = HCFileManager().iCloudBaseURL()
        case .localDrive:
            self.rootURL = HCFileManager().localBaseURL()
        case .photoLibrary:
            hcLog("잘못된 접근")
            fatalError()
        }

    }
    
    func initFileList() {
        guard let rootURL else { return }
        fileList =  hcFileManager.fetchContentList(source: rootURL)
            .filter { $0.isPhoto }
            .map({ FileBrowserItemModel(url: $0)})
    }
    
    func startFetchingThumb(index: Int, completion: @escaping (UIImage?) -> Void ) {
        guard index >= 0, index < fileList.count else { return }
        let item = fileList[index]
        
        if let image = item.highThumbnailImage {
            completion(image)
            
        } else if let image = item.lowThumbnailImage {
            completion(image) //
            hcFileManager.generateThumbnail(url: item.url,
                                            size: self.thumbnailSize) { type, fetchedImage in
                if type == .thumbnail, let highImage = fetchedImage {
                    item.highThumbnailImage = highImage
                    completion(highImage)
                } else if type == .icon {
                    hcLog("아이콘은 무시")
                } else {
                    completion(nil)
                }
            }
            
        } else {
            hcFileManager.generateThumbnail(url: item.url,
                                            size: self.thumbnailSize) { type, fetchedImage in
                if let fetchedImage {
                    if type == .lowQualityThumbnail {
                        item.lowThumbnailImage = fetchedImage
                    } else if type == .thumbnail {
                        item.highThumbnailImage = fetchedImage
                    }
                }
                completion(fetchedImage)
            }
        }
        
    }
    
    func stopFetchingThumb(index: Int) {
        guard index >= 0, index < fileList.count else { return }
        let item = fileList[index]
        guard let request = item.thumbnailRequest else { return }
        hcFileManager.stopGeneratingThumbnail(request: request)
    }
    
    func sharingFiles(_ indices:[Int]) -> [URL]? {
        var shareObject = [URL]()
        indices.forEach { index in
            shareObject.append(fileList[index].url)
        }
        return shareObject
    }
    
    func deleteFiles(_ indices:[Int]) {
        
    }
}

class FileBrowserItemModel {
    internal init(url: URL, thumbnailRequest: QLThumbnailGenerator.Request? = nil, lowThumbnailImage: UIImage? = nil, highThumbnailImage: UIImage? = nil, originalImage: UIImage? = nil) {
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
}
