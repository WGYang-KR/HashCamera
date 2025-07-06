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
import AVFoundation

class PhotoListVM {
    
    private var fileService = FileService()
    private let qlThumbnailGenerator =  QLThumbnailGenerator.shared

    private(set) var rootFolder: LocalFolderModel?
    var thumbnailSize: CGSize = .zero
    
    private(set) var fileList: [ImageFileModel] = []
    let fileListUpdatedRx = PublishRelay<FileListUpdateData>()
    
    var selectedIndexPaths: [IndexPath] = []
    
    struct FileListUpdateData {
        let folderUpdateData: FolderMonitor.FolderUpdateData
        let selectedIndexPaths: [IndexPath]
    }
    
    ///파일 목록 불러오기. 파일 변경 감시 시작. 호출할 때마다 reset 된다.
    func configure(rootFolder: LocalFolderModel) {
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
                
            case .changed(let deletedIndice, let addedIndice):
                //삭제된 폴더 뒤에서 부터 제거
                deletedIndice.reversed().forEach { deletedIndex in
                    self.fileList.remove(at: deletedIndex)
                }
                
                //추가된 폴더 뒤에서 부터 추가
                addedIndice.reversed().forEach { addedIndex in
                    let newItem = ImageFileModel(url: updateData.newFileList[addedIndex])
                    self.fileList.insert(newItem, at: addedIndex)
                }
            case .filesUpdated:
                break
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
    
    func durationString(index: Int) -> String? {
        guard let duration = duration(index: index), duration.isFinite, duration > 0 else {
               return nil
           }
           let minutes = Int(duration) / 60
           let seconds = Int(duration) % 60
           return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func duration(index: Int) -> Double? {
        guard index >= 0, index < fileList.count else { return nil }
        
        let item = fileList[index]
        let asset = AVAsset(url: item.url)
        
        // 영상인지 확인
        let hasVideoTrack = !asset.tracks(withMediaType: .video).isEmpty
        guard hasVideoTrack else { return nil }
        
        let time = asset.duration
        guard time.isNumeric else { return nil }
        
        let seconds = CMTimeGetSeconds(time)
        return seconds.isFinite ? seconds : nil
    }
    
    func deleteFiles(at indexPaths: [IndexPath]) async -> Result<Void, FileService.DeleteError> {
        return await fileService.deleteFiles(indexPaths.map({$0.row}))
    }
    
    func selectedFiles() -> [ImageFileModel] {
        return self.selectedIndexPaths.map({ fileList[$0.item] })
    }
}


