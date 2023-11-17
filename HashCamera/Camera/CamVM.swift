//
//  CamVM.swift
//  HashCamera
//
//  Created by WG-MacHome on 11/16/23.
//

import Foundation
import RxSwift
import RxRelay

class CamVM {
    let cameraModel: CameraModel
    let storageModel: StorageModel
    
    let isLoading = BehaviorRelay(value: false)
    var disposeBag = DisposeBag()
    
    init(cameraModel: CameraModel, storageModel: StorageModel) {
        self.cameraModel = cameraModel
        self.storageModel = storageModel
        initVM()
    }
    
    func initVM() {
    
        ///사진 캡처결과 받아서 저장소에 저장하기 연결
        cameraModel.capturedPhotoData.bind { [weak self] photoData in
            Task(priority: .high) { [weak self] in
                guard let self else { return }
                let result = await storageModel.savePhoto(photoData: photoData)
                isLoading.accept(false)
            }
            
        }.disposed(by: disposeBag)
    }
    
    ///사진 촬영
    func capturePhoto() {
        isLoading.accept(true)
        cameraModel.capturePhoto()

    }
    
}
