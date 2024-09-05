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
    ㄹㄷ
    var rootURL: URL? = URL(string: "./", relativeTo: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first)
    var thumbnailSize: CGSize = .zero
    
    var folderList: [[FolderListItemModel]]?
    var fileList = [ImageFileModel]()
    var selectedFolderIndexPath: IndexPath?

    var folderListUpdated: ((FolderMonitor.FolderUpdateData) -> Void)?
    var fileListUpdated: ((FolderMonitor.FolderUpdateData) -> Void)?
    typealias SelectionChangeData = (indexPath: IndexPath, animated: Bool)
    var seletedFolderChanged: ((SelectionChangeData) -> Void)?
    
    func prepare() {
        guard let rootURL else { return }
        fileService.configure(rootURL: rootURL, fileListUpdated: {  [weak self] folderUpdatedData in
            guard let self else { return }
            let newFileList = folderUpdatedData.newFileList.filter { $0.isPhoto }
            let addedList = folderUpdatedData.addedFiles.filter { $0.isPhoto }
            let deletedList = folderUpdatedData.removedFiles.filter{$0.isPhoto}
            self.fileList = newFileList.map({.init(url: $0)})
            self.fileListUpdated?(.init(newFileList: newFileList, addedFiles: addedList, removedFiles: deletedList))
        })
        
        folderService.configure(rootURL: rootURL, folderListUpdated: { [weak self] folderUpdatedData in
            guard let self else { return }
            
            //모든 사진, 분류안됨 폴더를 section 0에 추가하면서 폴더 목록 갱신한다.
            let virtualFolders: [FolderListItemModel] = [.init(type: .allPhotos, url: rootURL),
                                                         .init(type: .unclassified, url: rootURL)]
            let newFolderList = folderUpdatedData.newFileList.filter { $0.isDirectory }
            let addedList = folderUpdatedData.addedFiles.filter { $0.isDirectory }
            let removedList = folderUpdatedData.removedFiles.filter{$0.isDirectory}
            
            //이전 선택되었던 URL 저장
            var previousSelectedItem: FolderListItemModel?
            if let row = self.selectedFolderIndexPath?.row,
               let section = self.selectedFolderIndexPath?.section,
               let folderList,
               folderList.count >= section,
               folderList[section].count >= row {
                previousSelectedItem = folderList[section][row]
            
            }
     
         
            self.folderList = [virtualFolders,newFolderList.map({.init(type: .folder, url: $0)})]
            self.fileListUpdated?(.init(newFileList: newFolderList, addedFiles: addedList, removedFiles: removedList))
            
            //TODO: 갱신 후 선택처리
            guard let folderList else { return } // 목록 비어 있는 지 확인
            if let addedFolder = addedList.first { //폴더 추가 or 폴더 이름 변경
                if let index = newFolderList.firstIndex(of: addedFolder) {
                    self.selectedFolderIndexPath = .init(row: index, section: 1)
                } else {
                    self.selectedFolderIndexPath = .init(row: 0, section: 0)
                }
            } else if let removedFolder = removedList.first { // 폴더 제거됨
                if let previousSelectedItem {
                    //TODO: 이전에 선택되었던 폴더가 아직 있으면 그대로 유지. 없으면 all Photos로 선택 이동.
                    if let prevFolderIndex = folderList[0].firstIndex(where: { $0.url == previousSelectedItem.url }) {
                        self.selectedFolderIndexPath = .init(row: 0, section: prevFolderIndex)
                    } else if let prevFolderIndex = folderList[1].firstIndex(where: { $0.url == previousSelectedItem.url }) {
                        self.selectedFolderIndexPath = .init(row: 1, section: prevFolderIndex)
                    } else {
                        self.selectedFolderIndexPath = .init(row: 0, section: 0)
                    }
                } else {
                    self.selectedFolderIndexPath = .init(row: 0, section: 0)
                }
            
            } else { //초기 패칭
                self.selectedFolderIndexPath = .init(row: 0, section: 0)
            }
           
        })
            
//        ///선택된 폴더 index가 바뀌면, 바뀐 폴더의 파일목록을 가져온다.
//        selectedFolderIndexPath.subscribe{ [weak self] indexPath in
//            guard let self else { return }
//            guard indexPath.section < folders.value.count,
//                  indexPath.row < folders.value[indexPath.section].count
//            else { return }
//            Task { [weak self] in
//                guard let self else {return }
//                await fileService.fetchFiles(of: folders.value[indexPath.section][indexPath.row].url)
//            }
//        }.disposed(by: disposeBag)
//        
//        Task {
//            folderService.prepare()
//            await folderService.fetchFolders() //폴더 조회
//        }
    }
    
    
//    func startFetchingThumb(index: Int, completion: @escaping (UIImage?) -> Void ) {
//        guard index >= 0, index < files.value.count else { return }
//        let item = files.value[index]
//        
//        //기존 Request 있으면 취소
//        if let request = item.thumbnailRequest {
//            QLThumbnailGenerator.shared.cancel(request)
//        }
//        
//        //새 Request 요청
//        let scale = UIScreen.main.scale
//    
//        let request = QLThumbnailGenerator.Request(fileAt: item.url,
//                                                   size: self.thumbnailSize,
//                                                   scale: scale,
//                                                   representationTypes: [.lowQualityThumbnail, .thumbnail])
//        
//        QLThumbnailGenerator.shared.generateRepresentations(for: request) { thumbnail, type, error in
//            if let thumbnail {
//                completion(thumbnail.uiImage)
//            } else if let error {
//                hcLog("\(error): \(error.localizedDescription)")
//                hcLog("\(item.url.lastPathComponent) Thumnail error")
//                completion(nil)
//            }
//        }
//    }
//    
//    func stopFetchingThumb(index: Int) {
//        guard index >= 0, index < files.value.count else { return }
//        if let request = files.value[index].thumbnailRequest {
//            QLThumbnailGenerator.shared.cancel(request)
//        }
//    }
//    
//    
//    
//    ///해당 Index 파일들의 URL을 반환한다.
//    func sharingFiles(_ indices:[Int]) -> [URL]? {
//        var shareObject = [URL]()
//        indices.forEach { index in
//            shareObject.append(files.value[index].url)
//        }
//        return shareObject
//    }
//    
//    ///파일을 삭제한다. 일부 파일이 삭제 실패했을 경우에는 false를 반환하면서 error와 실패한 url 리스트를 반환한다.
//    /// - Parameter urlList: 삭제할 파일 url 배열
//    /// - Returns: (모든 파일 삭제 성공여부, 실패시 에러, 실패한 파일목록)
//    func deleteFiles(_ indices:[Int]) -> (success: Bool, error: Error?, failedURLs: [URL]) {
//        var deletingURLs = [URL]()
//        indices.forEach { index in
//            deletingURLs.append(files.value[index].url)
//        }
//        
//        /// 파일을 삭제한다. 일부 파일이 삭제 실패했을 경우에는 false를 반환하면서 error와 실패한 url 리스트를 반환한다.
//        /// - Parameter urlList: 삭제할 파일 url 배열
//        /// - Returns: (모든 파일 삭제 성공여부, 실패시 에러, 실패한 파일목록)
//        func deleteFile(urlList: [URL]) -> (success: Bool, error: Error?, failedURLs: [URL]) {
//            
//            var failedURLs = [URL]() //삭제 실패한 파일목록
//            var lastError:Error? = nil //삭제 실패 에러
//            
//            urlList.forEach { url in
//                do {
//                    try fileManager.removeItem(at: url)
//                } catch(let error) {
//                    failedURLs.append(url)
//                    lastError = error
//                }
//            }
//            
//            return (success: failedURLs.count == 0 , error: lastError, failedURLs: failedURLs)
//            
//        }
//        
//        return deleteFile(urlList: deletingURLs)
//    }
//    
//
//    
    //MARK: FolderListVMProtocol
    func createFolder(folderName: String) async -> Result<URL, FolderService.CreationError> {
        await folderService.createFolder(folderName: folderName)
    }
    
    func renameFolder(at indexPath: IndexPath, newName: String) async -> Result<URL, FolderService.RenameError> {
        guard folders.value[indexPath.section][indexPath.row].type == .folder else { return .failure(.isNotRealFolder) }
        return await folderService.renameFolder(at: indexPath.row, newName: newName)
    }
    
    func deleteFolder(at indexPath: IndexPath) async -> Result<Void, FolderService.DeleteError> {
        guard folders.value[indexPath.section][indexPath.row].type == .folder else { return .failure(.isNotRealFolder) }
        return await folderService.deleteFolder(at: indexPath.row)
    }
    
    
}


