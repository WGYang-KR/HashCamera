//
//  CamVC.swift
//  HashCamera
//
//  Created by WG-Yang on 10/24/23.
//

import UIKit
import RxSwift
import RxRelay
import SnapKit

class CamVC: UIViewController {

    
    @IBOutlet weak var topMenuView: TopMenuBarView!
 
    @IBOutlet weak var previewView: CameraPreviewView!
    @IBOutlet weak var preview916GuideView: UIView!
    @IBOutlet weak var preview34GuideView:UIView!
    
    @IBOutlet weak var bottomMenuContainer: UIView!
    @IBOutlet weak var storageButton: UIButton!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var browseButton: UIButton!
   
    @IBOutlet weak var storageBarView: StorageBarCollectionView!
    let cameraModel: CameraModel = CameraModel(position: .back,
                                                 flashMode: .off, aspectRatio: .standard, fileType: .jpeg)
    let storageModel: StorageModel = StorageModel(selectedStorgeType: .photoLibrary)
    
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        enableComponents(false)
        Task {
            if await AuthorizationManager.checkCameraAuth() {
                let _ = await cameraModel.startCamera()
            
                enableComponents(true)
            } else {
                AuthorizationManager.presentCameraAuthAlert(baseVC: self)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        enableComponents(false)
        Task {
            let _ = await cameraModel.stopCamera()
        }
    }
    func initView() {

        previewView.snp.makeConstraints { make in
            make.edges.equalTo(preview34GuideView)
        }
        
        previewView.session = cameraModel.captureSession
        
        storageButton.rx.tap.bind(onNext: { [weak self] in
                guard let self else { return }
                storageButton.isHidden = storageButton.isHidden == true ? false : true
        }).disposed(by: disposeBag)
        
        storageBarView.seletedStorage.bind { [weak self] storageType in
            guard let self else { return }
            storageModel.selectedStorgeType.accept(storageType)
        }.disposed(by: disposeBag)
        
        topMenuView.aspectRatioRx.bind { [weak self] aspectRatio in
            self?.cameraModel.aspectRatio.accept(aspectRatio)
        }.disposed(by: disposeBag)
        
        topMenuView.flashModeRx.bind { [weak self] flashMode in
            self?.cameraModel.flashMode.accept(flashMode)
        }.disposed(by: disposeBag)
        
        topMenuView.cameraPositionRx.bind { [weak self] cameraPosition in
            self?.cameraModel.position.accept(cameraPosition)
        }.disposed(by: disposeBag)
        
        captureButton.rx.tap.bind { [weak self] _ in
            guard let self else { return }
            enableComponents(false)
            Task {
                let _ = await self.cameraModel.capture()
                self.enableComponents(true)
            }
        }.disposed(by: disposeBag)
        
    }
    
    ///화면 모든 버튼 활성화/비활성화
    func enableComponents(_ isEnabled: Bool) {
        topMenuView.moreMenuBtn.isEnabled = isEnabled
        topMenuView.aspectRatioBtn.isEnabled = isEnabled
        topMenuView.flashModeBtn.isEnabled = isEnabled
        topMenuView.cameraPositionBtn.isEnabled = isEnabled
        storageButton.isEnabled = isEnabled
        captureButton.isEnabled = isEnabled
        browseButton.isEnabled = isEnabled
    }
    



}
