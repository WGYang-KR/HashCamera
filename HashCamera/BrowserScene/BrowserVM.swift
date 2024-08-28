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

    var disposeBag = DisposeBag()
    let fileManager = FileManager.default
    let qlThumbnailGenerator =  QLThumbnailGenerator.shared
    let folderService = FolderService.shared
    let fileService = FileService.shared
    let folders = BehaviorRelay<[[FolderListItemModel]]>(value: [[]])
    var files: BehaviorRelay<[ImageFileModel]> { fileService.files }
    let selectedFolderIndexPath = BehaviorRelay<IndexPath>(value:.init(row: 0, section: 0))
    
    var thumbnailSize: CGSize = .zero
    
    func prepare() {
        
        folderService.folders.withUnretained(self).subscribe{owner, list in
            guard let rootURL = owner.folderService.rootURL else { return }
            //모든 사진, 분류안됨 폴더를 section 0에 추가하면서 폴더 목록 갱신한다.
            let virtualFolders: [FolderListItemModel] = [.init(type: .allPhotos, url: rootURL),
                                                         .init(type: .unclassified, url: rootURL)]
            owner.folders.accept([virtualFolders,list])
            owner.selectedFolderIndexPath.accept(.init(row: 0, section: 0))
        }.disposed(by: disposeBag)

        ///선택된 폴더 index가 바뀌면, 바뀐 폴더의 파일목록을 가져온다.
        selectedFolderIndexPath.subscribe{ [weak self] indexPath in
            guard let self else { return }
            guard indexPath.section < folders.value.count,
                  indexPath.row < folders.value[indexPath.section].count
            else { return }
            Task { [weak self] in
                guard let self else {return }
                await fileService.fetchFiles(of: folders.value[indexPath.section][indexPath.row].url)
            }
        }.disposed(by: disposeBag)
        
        Task {
            folderService.prepare()
            await folderService.fetchFolders() //폴더 조회
        }
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


