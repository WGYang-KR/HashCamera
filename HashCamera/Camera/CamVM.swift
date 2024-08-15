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
    
    
    ///촬영시 true -> 저장 완료 후 false
    let isCapturingPhoto = BehaviorRelay(value: false)
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
                let result = await storageModel.savePhoto(photoData: photoData) //저장소 저장
                hcLog("\(result.0)")
                await MainActor.run { [weak self] in
                    self?.isCapturingPhoto.accept(false) //촬영저장 끝
                }
            }
            
        }.disposed(by: disposeBag)
    }
    
    ///사진 촬영
    func capturePhoto() {
        isCapturingPhoto.accept(true) //촬영 저장 시작
        cameraModel.capturePhoto() //촬영 후 결과값은 capturedPhotoData로 수신
    }
    
}
