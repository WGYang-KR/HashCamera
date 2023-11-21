//
//  StorageModel.swift
//  HashCamera
//
//  Created by WG-MacHome on 11/13/23.
//

import UIKit
import RxSwift
import RxRelay
import Photos

class StorageModel {
    
    let selectedStorgeType: BehaviorRelay<StorageType>
    var photoFileType: PhotoFileType //사진 파일형식
    let hcFileManager = HCFileManager()
    
    init(selectedStorgeType: StorageType, photoFileType: PhotoFileType = .jpeg) {
        self.selectedStorgeType = BehaviorRelay<StorageType>(value: selectedStorgeType)
        self.photoFileType = photoFileType
    }
    
    ///선택된 저장소에 사진을 저장. 실패하면 에러 반환.
    func savePhoto(photoData: Data) async -> (Bool, Error?){
        switch selectedStorgeType.value {
        case .photoLibrary:
            return await savePhotoInPhotoLibrary(data: photoData, metaData: PhotoMetaData(creationDate: Date()))
        case .iCloudDrive:
            let success = savePhotoIniCloud(data: photoData) != nil ? true : false
            return (success, success ? nil : HCError.failSaveiCloud)
        case .localDrive:
            let success = savePhotoInLocal(data: photoData) != nil ? true : false
            return (success, success ? nil : HCError.failSaveLocal)
        }
    }
    
    
    struct PhotoMetaData {
        var creationDate: Date?
        var location: CLLocation?
        var isFavorite: Bool = false
        var isHidden: Bool = false
    }
    
      
    ///사진라이브러리에 사진을 저장. 실패하면 에러 반환.
    private func savePhotoInPhotoLibrary(data: Data, metaData: PhotoMetaData) async -> (Bool, Error?) {
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let createAssetrequest = PHAssetCreationRequest.forAsset()
                createAssetrequest.addResource(with: .photo, data: data, options: nil)
            }
            return (true,  nil)
            
        } catch(let error) {
            return (false, error)
        }
        
    }
    
    //iCloud>HashCamera>Document 에 사진을 저장. 실패하면 nil 반환.
    private func savePhotoIniCloud(data: Data) -> URL? {
        guard let baseURL = hcFileManager.iCloudBaseURL() else { return nil }
        let fileName = makePhotoFileName(fileTypeString: self.photoFileType.rawValue)
        return hcFileManager.saveFile(destination: baseURL, data: data, fileName: fileName)
        
    }
    
    //local>HashCame>Document 에 사진을 저장. 실패하면 nil 반환.
    private func savePhotoInLocal(data: Data) -> URL? {
        guard let baseURL = hcFileManager.localBaseURL() else { return nil }
        let fileName = makePhotoFileName(fileTypeString: self.photoFileType.rawValue)
        return hcFileManager.saveFile(destination: baseURL, data: data, fileName: fileName)
        
    }
    
    //현재시간을 베이스로 파일명을 반환
    private func makePhotoFileName(fileTypeString: String ) -> String {
        let format = "yyyyMMdd_HHmmss_SSS"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        let timeString = dateFormatter.string(from: Date())
        return timeString + "." + fileTypeString
    }
}
