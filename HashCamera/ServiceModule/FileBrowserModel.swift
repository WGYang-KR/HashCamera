//
//  FileBrowserModel.swift
//  HashCamera
//
//  Created by WG-MacHome on 12/2/23.
//

import UIKit
import QuickLookThumbnailing
import Combine

class FileBrowserModel {
    
    var storageType: StorageType
    var rootURL: URL?
    var fileList =  CurrentValueSubject<[MediaFileModel],Never>([])
    let hcFileManager = HCFileManager()
    var thumbnailSize: CGSize
    let qlThumbnailGenerator =  QLThumbnailGenerator.shared
    let folderMonitor: FolderMonitor //폴더 변경 감시자

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
        
        self.folderMonitor = FolderMonitor(url: self.rootURL)
        folderMonitor.folderDidChange = { [weak self] in
            self?.initFileList()
        }
        folderMonitor.startMonitoring()

    }
    
    func initFileList() {
        guard let rootURL else { return }
        Task { [weak self ] in
            guard let self else { return }
            let list = hcFileManager.fetchContentList(source: rootURL)
                .filter { $0.isPhoto }
                .map({ MediaFileModel(
                    url: $0)})
            await MainActor.run { [weak self] in
                self?.fileList.send( list)
            }
        }
    
    
    }
    
    func startFetchingThumb(index: Int, completion: @escaping (UIImage?) -> Void ) {
        guard index >= 0, index < fileList.value.count else { return }
        let item = fileList.value[index]
        
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
        guard index >= 0, index < fileList.value.count else { return }
        let item = fileList.value[index]
        guard let request = item.thumbnailRequest else { return }
        hcFileManager.stopGeneratingThumbnail(request: request)
    }
    
    ///해당 Index 파일들의 URL을 반환한다.
    func sharingFiles(_ indices:[Int]) -> [URL]? {
        var shareObject = [URL]()
        indices.forEach { index in
            shareObject.append(fileList.value[index].url)
        }
        return shareObject
    }
    
    ///파일을 삭제한다. 일부 파일이 삭제 실패했을 경우에는 false를 반환하면서 error와 실패한 url 리스트를 반환한다.
    /// - Parameter urlList: 삭제할 파일 url 배열
    /// - Returns: (모든 파일 삭제 성공여부, 실패시 에러, 실패한 파일목록)
    func deleteFiles(_ indices:[Int]) -> (success: Bool, error: Error?, failedURLs: [URL]) {
        var deletingURLs = [URL]()
        indices.forEach { index in
            deletingURLs.append(fileList.value[index].url)
        }
        return hcFileManager.deleteFile(urlList: deletingURLs)
    }
    
    deinit {
        self.folderMonitor.stopMonitoring()
    }
}

