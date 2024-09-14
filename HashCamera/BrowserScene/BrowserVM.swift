//
//  BrowserVM.swift
//  HashCamera
//
//  Created by Anto-Yang on 7/18/24.
//

import UIKit
import RxSwift
import RxRelay
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

class BrowserVM {

    private var disposeBag = DisposeBag()
    private let fileManager = FileManager.default
    private let qlThumbnailGenerator =  QLThumbnailGenerator.shared
    private let folderService = FolderService()
    private let fileService = FileService.shared
    
    var rootURL: URL? = URL(string: "./", relativeTo: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first)
    var thumbnailSize: CGSize = .zero
    
    var folderList: [[FolderListItemModel]]?
    var files = BehaviorRelay(value:[ImageFileModel]())
    var selectedFolderIndexPath: IndexPath?

    var folderListUpdated: ((FolderMonitor.FolderUpdateData) -> Void)?
    var fileListUpdated: ((FolderMonitor.FolderUpdateData) -> Void)?
    typealias SelectionChangeData = (indexPath: IndexPath, animated: Bool)
    var seletedFolderChanged: ((SelectionChangeData) -> Void)?
    
    func prepare() {
        guard let rootURL else { return }
        
        fileService.configure(rootURL: rootURL, fileListUpdated: {  [weak self] folderUpdatedData in
            guard let self else { return }
//            let newFileList = folderUpdatedData.newFileList.filter { $0.isPhoto }
//            let addedList = folderUpdatedData..addedFiles.filter { $0.isPhoto }
//            let deletedList = folderUpdatedData.removedFiles.filter{$0.isPhoto}
//            self.fileList = newFileList.map({.init(url: $0)})
//            self.fileListUpdated?(.init(newFileList: newFileList, addedFiles: addedList, removedFiles: deletedList))
        })
        
        
        
        
    }
    
    
    func startFetchingThumb(index: Int, completion: @escaping (UIImage?) -> Void ) {
        guard index >= 0, index < files.value.count else { return }
        let item = files.value[index]
        
        //기존 Request 있으면 취소
        if let request = item.thumbnailRequest {
            QLThumbnailGenerator.shared.cancel(request)
        }
        
        //새 Request 요청
        let scale = UIScreen.main.scale
    
        let request = QLThumbnailGenerator.Request(fileAt: item.url,
                                                   size: self.thumbnailSize,
                                                   scale: scale,
                                                   representationTypes: [.lowQualityThumbnail, .thumbnail])
        
        QLThumbnailGenerator.shared.generateRepresentations(for: request) { thumbnail, type, error in
            if let thumbnail {
                completion(thumbnail.uiImage)
            } else if let error {
                hcLog("\(error): \(error.localizedDescription)")
                hcLog("\(item.url.lastPathComponent) Thumnail error")
                completion(nil)
            }
        }
    }
    
    func stopFetchingThumb(index: Int) {
        guard index >= 0, index < files.value.count else { return }
        if let request = files.value[index].thumbnailRequest {
            QLThumbnailGenerator.shared.cancel(request)
        }
    }
    
    
    
    ///해당 Index 파일들의 URL을 반환한다.
    func sharingFiles(_ indices:[Int]) -> [URL]? {
        var shareObject = [URL]()
        indices.forEach { index in
            shareObject.append(files.value[index].url)
        }
        return shareObject
    }
    
    ///파일을 삭제한다. 일부 파일이 삭제 실패했을 경우에는 false를 반환하면서 error와 실패한 url 리스트를 반환한다.
    /// - Parameter urlList: 삭제할 파일 url 배열
    /// - Returns: (모든 파일 삭제 성공여부, 실패시 에러, 실패한 파일목록)
    func deleteFiles(_ indices:[Int]) -> (success: Bool, error: Error?, failedURLs: [URL]) {
        var deletingURLs = [URL]()
        indices.forEach { index in
            deletingURLs.append(files.value[index].url)
        }
        
        /// 파일을 삭제한다. 일부 파일이 삭제 실패했을 경우에는 false를 반환하면서 error와 실패한 url 리스트를 반환한다.
        /// - Parameter urlList: 삭제할 파일 url 배열
        /// - Returns: (모든 파일 삭제 성공여부, 실패시 에러, 실패한 파일목록)
        func deleteFile(urlList: [URL]) -> (success: Bool, error: Error?, failedURLs: [URL]) {
            
            var failedURLs = [URL]() //삭제 실패한 파일목록
            var lastError:Error? = nil //삭제 실패 에러
            
            urlList.forEach { url in
                do {
                    try fileManager.removeItem(at: url)
                } catch(let error) {
                    failedURLs.append(url)
                    lastError = error
                }
            }
            
            return (success: failedURLs.count == 0 , error: lastError, failedURLs: failedURLs)
            
        }
        
        return deleteFile(urlList: deletingURLs)
    }

}


