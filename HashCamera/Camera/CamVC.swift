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
    
    let viewBlurEffect = {
        let viewBlurEffect = UIVisualEffectView()
        //Blur Effect는 .light 외에도 .dark, .regular 등이 있으니 적용해보세요!
        viewBlurEffect.effect = UIBlurEffect(style: .light)
    }
    
    let camVM: CamVM = CamVM(cameraModel: CameraModel(position: .back,
                                                      flashMode: .off,
                                                      aspectRatio: .standard,
                                                      fileType: .jpeg),
                             storageModel: StorageModel(selectedStorgeType: .photoLibrary))
    var cameraModel: CameraModel { return  camVM.cameraModel }
    var storageModel: StorageModel { return camVM.storageModel}
    
    let isLoading = BehaviorRelay(value: true)
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        initCamera()
        bindAppLifeCycle()
        
        //isLoading Bind 초기값 true
        Observable.combineLatest(isLoading, cameraModel.isLoading, camVM.isLoading) { $0 || $1 || $2 }.bind { [weak self] isLoading in
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


        storageButton.rx.tap.bind(onNext: { [weak self] in
                guard let self else { return }
                storageBarView.isHidden = storageBarView.isHidden == true ? false : true
        }).disposed(by: disposeBag)
        
        storageBarView.seletedStorage.bind { [weak self] storageType in
            guard let self else { return }
            storageModel.selectedStorgeType.accept(storageType)
        }.disposed(by: disposeBag)
        
        topMenuView.aspectRatioRx.bind { [weak self] aspectRatio in
            self?.cameraModel.aspectRatio.accept(aspectRatio)
            self?.setPreviewAspectRatio(aspectRatio: aspectRatio)
        }.disposed(by: disposeBag)
        
        topMenuView.flashModeRx.bind { [weak self] flashMode in
            self?.cameraModel.flashMode.accept(flashMode)
        }.disposed(by: disposeBag)
        
        topMenuView.cameraPositionRx.bind { [weak self] cameraPosition in
            self?.cameraModel.position.accept(cameraPosition)
        }.disposed(by: disposeBag)
        
        captureButton.rx.tap.bind { [weak self] _ in
            guard let self else { return }
            captureEffect()
            cameraModel.capturePhoto()
        }.disposed(by: disposeBag)
        
        
        //캡처시 테두리 효과 색 지정.
        previewView.layer.borderColor = UIColor(resource: .majorLight).cgColor
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
    
    func captureEffect() {
        UIView.animate(withDuration: 0.1) {
            self.previewView.layer.borderWidth = 2
            
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            UIView.animate(withDuration: 0.1) {
                self.previewView.layer.borderWidth = 0
            }
        })
    }
    
    func setPreviewAspectRatio(aspectRatio: AspectRatioType) {

        UIView.animate(withDuration: 0.5) {[weak self] in
            guard let self else { return }
            previewView.snp.removeConstraints()
            switch aspectRatio {
            case .square:
                previewView.snp.makeConstraints { [weak self] make in
                    guard let self else  {return }
                    make.leading.trailing.equalTo(preview34GuideView)
                    make.centerY.equalTo(preview34GuideView)
                    make.width.equalTo(previewView.snp.height)
                }
            case .standard:
                previewView.snp.makeConstraints {  [weak self]  make in
                    guard let self else  {return }
                    make.edges.equalTo(preview34GuideView)
                }
            case .wide:
                previewView.snp.makeConstraints {[weak self] make in
                    guard let self else  {return }
                    make.edges.equalTo(preview916GuideView)
                }
            }
        }
    }



}
