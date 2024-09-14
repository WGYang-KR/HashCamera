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

    var rootURL: URL?
    var thumbnailSize: CGSize = .zero
    
    var fileList: [ImageFileModel] = []
    var fileListUpdated: ((FileListUpdateData) -> Void)?
    
    var selectedIndexPaths: [IndexPath] = []
    
    struct FileListUpdateData {
        let folderUpdateData: FolderMonitor.FolderUpdateData
        let selectedIndexPaths: [IndexPath]
    }
    
    ///파일 목록 불러오기. 파일 변경 감시 시작. 호출할 때마다 reset 된다.
    func configure(rootURL: URL, fileListUpdated: ((FileListUpdateData) -> Void)?) {
        self.rootURL = rootURL
        self.fileList = []
        self.fileListUpdated = fileListUpdated
        self.selectedIndexPaths = []
       
        fileService.configure(rootURL: rootURL,
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
                selectedIndexPaths = []
            case .delete(let deletedIndex):
                guard deletedIndex < fileList.count else { return }
                fileList.remove(at: deletedIndex)
                selectedIndexPaths = []
            case .rename(let oldIndex, let newIndex):
                guard oldIndex < fileList.count, newIndex <= fileList.count else { return }
                //새 이름을 갱신해야하므로 swap 안하고 삭제,삽입.
                fileList.remove(at: oldIndex)
                let newItem = ImageFileModel(url: updateData.newFileList[newIndex])
                fileList.insert(newItem, at: newIndex)
                selectedIndexPaths = []
            }
            
            //선택된 폴더정보 유지되도록 작업
            selectedIndexPaths = []
            
            //VC에 업데이트 이벤트 전달
            fileListUpdated?(.init(folderUpdateData: updateData, selectedIndexPaths: self.selectedIndexPaths))
            
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
        guard index >= 0, index < fileList.count else { return }
        if let request = fileList[index].thumbnailRequest {
            QLThumbnailGenerator.shared.cancel(request)
        }
    }
    
    func deleteFiles(at indexPaths: [IndexPath]) async -> Result<Void, FileService.DeleteError> {
        return await fileService.deleteFiles(indexPaths.map({$0.row}))
    }
    
}


