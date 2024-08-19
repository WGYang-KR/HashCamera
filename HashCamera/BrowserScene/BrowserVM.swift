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

    let fileManager = FileManager.default
    let qlThumbnailGenerator =  QLThumbnailGenerator.shared
    
    var rootURL: URL?
    let fileList = BehaviorRelay<[ImageFileModel]>(value: [])
    var thumbnailSize: CGSize = .zero
    let folderMonitor: FolderMonitor //폴더 변경 감시자

    
    init() {
        ///로컬폴더 rootURL 세팅
        if let baseURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first{
            let rootURL = URL(string: "./", relativeTo: baseURL)
            self.rootURL = rootURL
            
        }
        
        ///폴더 변경 감시자 세팅
        self.folderMonitor = FolderMonitor(url: self.rootURL)
        folderMonitor.folderDidChange = {
            Task { [weak self] in
                self?.initFileList
            }
        }
        
        folderMonitor.startMonitoring()
    }

    func initFileList() async {
        guard let rootURL else { return }
        
        do {
            let fetchedList =  try fileManager.contentsOfDirectory(at: rootURL,
                                                                   includingPropertiesForKeys: nil)
            hcLog("fetched list count = \(fetchedList.count)")
            let photoList = fetchedList.filter{$0.isPhoto}
            hcLog("photo file count = \(photoList.count)")
            
            await MainActor.run {
                fileList.accept(photoList.map{ImageFileModel(url: $0)})
            }
        } catch {
            hcLog("fetch error")
            await MainActor.run {
                fileList.accept([])
            }
        }
    }
    
    func startFetchingThumb(index: Int, completion: @escaping (UIImage?) -> Void ) {
        guard index >= 0, index < fileList.value.count else { return }
        let item = fileList.value[index]
        
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
        guard index >= 0, index < fileList.value.count else { return }
        if let request = fileList.value[index].thumbnailRequest {
            QLThumbnailGenerator.shared.cancel(request)
        }
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
    
    deinit {
        self.folderMonitor.stopMonitoring()
    }
}


