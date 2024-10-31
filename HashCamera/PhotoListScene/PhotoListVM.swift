//
//  PhotoListVM.swift
//  HashCamera
//
//  Created by Anto-Yang on 7/18/24.
//

import UIKit
import RxSwift
import RxRelay
import QuickLookThumbnailing

class PhotoListVM {
    
    private var fileService = FileService()
    private let qlThumbnailGenerator =  QLThumbnailGenerator.shared

    private(set) var rootFolder: FolderModel?
    var thumbnailSize: CGSize = .zero
    
    private(set) var fileList: [ImageFileModel] = []
    let fileListUpdatedRx = PublishRelay<FileListUpdateData>()
    
    var selectedIndexPaths: [IndexPath] = []
    
    struct FileListUpdateData {
        let folderUpdateData: FolderMonitor.FolderUpdateData
        let selectedIndexPaths: [IndexPath]
    }
    
    ///파일 목록 불러오기. 파일 변경 감시 시작. 호출할 때마다 reset 된다.
    func configure(rootFolder: FolderModel) {
        self.rootFolder = rootFolder
        self.fileList = []
        self.selectedIndexPaths = []
       
        fileService.configure(rootURL: rootFolder.url,
                              fileListUpdated: {[weak self] updateData in
            //업데이트 이벤트 핸들러
            guard let self else { return }
            
            //각 상황에 맞게 파일목록 업데이트
            switch updateData.changeType {
            case .initiate:
                fileList = updateData.newFileList.map({ImageFileModel(url: $0)})
            case .add(let newIndex):
                guard newIndex <= fileList.count else { return }
                let newItem = ImageFileModel(url: updateData.newFileList[newIndex])
                fileList.insert(newItem, at: newIndex)
            case .delete(let deletedIndex):
                guard deletedIndex < fileList.count else { return }
                fileList.remove(at: deletedIndex)
            case .rename(let oldIndex, let newIndex):
                guard oldIndex < fileList.count, newIndex <= fileList.count else { return }
                //새 이름을 갱신해야하므로 swap 안하고 삭제,삽입.
                fileList.remove(at: oldIndex)
                let newItem = ImageFileModel(url: updateData.newFileList[newIndex])
                fileList.insert(newItem, at: newIndex)
            }
            
            //선택된 파일 초기화
            selectedIndexPaths = []
            
            //VC에 업데이트 이벤트 전달
            fileListUpdatedRx.accept(.init(folderUpdateData: updateData, selectedIndexPaths: self.selectedIndexPaths))
            
        })
    }
    
    
    
    func startFetchingThumb(index: Int, completion: @escaping (UIImage?) -> Void ) {
        guard index >= 0, index < fileList.count else { return }
        let item = fileList[index]
        
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
        item.thumbnailRequest = request
        QLThumbnailGenerator.shared.generateRepresentations(for: request) { thumbnail, type, error in
            if let thumbnail {
                item.thumbnailImage = thumbnail.uiImage
                completion(thumbnail.uiImage)
            } else if let error {
                hcLog("\(error): \(error.localizedDescription)")
                hcLog("\(item.url.lastPathComponent) Thumnail error")
                item.thumbnailImage = nil
                completion(nil)
            }
        }
    }
    
    func stopFetchingThumb(index: Int) {
        guard index >= 0, index < fileList.count else { return }
        if let request = fileList[index].thumbnailRequest {
            QLThumbnailGenerator.shared.cancel(request)
        }
    }
    
    func deleteFiles(at indexPaths: [IndexPath]) async -> Result<Void, FileService.DeleteError> {
        return await fileService.deleteFiles(indexPaths.map({$0.row}))
    }
    
    func selectedFiles() -> [ImageFileModel] {
        return self.selectedIndexPaths.map({ fileList[$0.item] })
    }
}


