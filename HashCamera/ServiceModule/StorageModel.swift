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
    
    init(selectedStorgeType: StorageType) {
        self.selectedStorgeType = BehaviorRelay<StorageType>(value: selectedStorgeType)
    }
    
    ///선택된 저장소에 사진을 저장. 실패하면 에러 반환.
    func savePhoto(photoData: Data) async -> (Bool, Error?){
        switch selectedStorgeType.value {
        case .photoLibrary:
            return await savePhotoInPhotoLibrary(data: photoData, metaData: PhotoMetaData(creationDate: Date()))
        case .iCloudDrive:
            return (false, HCError.failSaveiCloud)
        case .localDrive:
            return (false, HCError.failSaveLocal)
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
}
