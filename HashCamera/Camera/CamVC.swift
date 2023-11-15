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
    
    let isLoading = BehaviorRelay(value: true)
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        initCamera()
        bindAppLifeCycle()
        
        //isLoading Bind 초기값 true
        Observable.combineLatest(isLoading, cameraModel.isLoading) { $0 || $1 }.bind { [weak self] isLoading in
            Task {
                await MainActor.run {
                    self?.enableComponents( !isLoading )
                }
            }
        }.disposed(by: disposeBag)
        
     
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startCamera()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopCamera()
    }
    
    func bindAppLifeCycle() {
        
        //앱이 활성화 될때
        AppLifeCycle.sceneDidBecomeActive.bind { [weak self] _ in
            hcLog("sceneDidBecomeActive")
            self?.startCamera()
        }.disposed(by: disposeBag)
        
        //앱이 비활성화 될때
        AppLifeCycle.sceneWillResignActive.bind { [weak self] _ in
            hcLog("sceneWillResignActive")
            self?.stopCamera()
        }.disposed(by: disposeBag)
        
    }
    
    func initCamera() {
        previewView.session = cameraModel.captureSession
        cameraModel.initCamera()
    }
    
    func startCamera() {
        Task {
            if await AuthorizationManager.checkCameraAuth() { //권한 확인
                let _ = await cameraModel.startCamera() //프리뷰 시작.
            
                isLoading.accept(false) //화면 활성화
            } else {
                AuthorizationManager.presentCameraAuthAlert(baseVC: self)
            }
        }
    }
    
    func stopCamera() {
        isLoading.accept(true)  //화면 비활성화
        Task {
            let _  = await cameraModel.stopCamera()
        }
    }
    
    func initView() {

        previewView.snp.makeConstraints { make in
            make.edges.equalTo(preview34GuideView)
        }

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
            isLoading.accept(true)
            Task { [weak self] in
                let _ = await self?.cameraModel.capture()
                self?.isLoading.accept(false)
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
