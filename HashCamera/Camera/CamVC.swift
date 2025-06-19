//
//  CamVC.swift
//  HashCamera
//
//  Created by WG-Yang on 10/24/23.
//

import UIKit
import SwiftUI
import RxSwift
import RxRelay
import SnapKit
import FirebaseCrashlytics

class CamVC: UIViewController {
    
    var disposeBag = DisposeBag()
    
    @IBOutlet weak var rootContView: UIView!
    @IBOutlet weak var topMenuView: TopMenuBarView!
 
    @IBOutlet weak var previewView: CameraPreviewView!
    @IBOutlet weak var preview916GuideView: UIView!
    @IBOutlet weak var preview34GuideView:UIView!
    
    @IBOutlet weak var bottomMenuContainer: UIView!
    @IBOutlet weak var bottomMenuTopSpaceView: UIView!
    @IBOutlet weak var storageButton: UIButton!
    @IBOutlet weak var captureButton: CaptureBtnView!
    @IBOutlet weak var browseButton: UIButton!
    
    @IBOutlet weak var zoomFactorBtn: UIButton!
    @IBOutlet weak var photoVideoSegControl: UISegmentedControl!
    @IBOutlet weak var timeLabel: UILabel!
    
    let camVM: CamVM = CamVM()
    let isLoading = BehaviorRelay(value: true)

    var didOnceAppear = false //화면 표시가 완료되었는지.
    
    // 상태 바를 숨길지 결정
    override var prefersStatusBarHidden: Bool { true }
    
    var captureMode: CaptureModeType = .photo
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        initCamera()
        bindAppLifeCycle()
        
        camVM.isCapturingPhoto.observe(on: MainScheduler.instance).bind { [weak self] isCapturing in
            self?.enableComponents( !isCapturing )
            if isCapturing {
                self?.previewView.opaqueEffect()
            }
        }.disposed(by: disposeBag)
        NotificationCenter.default.addObserver(self, selector: #selector(self.widgetFolderTapped), name: .widgetFolderTapped, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.widgetSettingTapped), name: .widgetSettingTapped, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.widgetCameraTapped), name: .widgetCameraTapped, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        didOnceAppear = true
        startCamera()
        doWidgetOrderIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopCamera()
    }
    
    override func viewDidLayoutSubviews() {

        storageButton.layer.cornerRadius = storageButton.bounds.height / 2
        zoomFactorBtn.layer.cornerRadius = zoomFactorBtn.bounds.height / 2

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
        previewView.session = camVM.cameraModel.captureSession
        camVM.cameraModel.initCamera()
        
        enableComponents(false) //초기화시 이벤트 블락
        previewView.blurEffect(true) // 블러처리
    }
    
    func startCamera() {
        Task {
            if await AuthorizationManager.checkCameraAuth() { //권한 확인
                    camVM.cameraModel.startCamera() { [weak self] in //프리뷰 시작.
                        DispatchQueue.main.async {
                            self?.enableComponents(true)
                            self?.previewView.blurEffect(false)
                        }
                    }
            } else {
                AuthorizationManager.presentCameraAuthAlert(baseVC: self) {[weak self]_ in
                    guard let self else { return }
                    enableComponents(false)
                    browseButton.isEnabled = true
                }
            }
        }
    }
    
    func stopCamera() {
        enableComponents(false)
        previewView.blurEffect(true)
        camVM.cameraModel.stopCamera()
    }
    
    func initView() {

        //폴더선택 화면 표시
        storageButton.rx.tap.bind(onNext: { [weak self] in
            guard let self else { return }
            let vc = SelectSaveFolderVC()
            vc.configure(delegate: camVM, initialSelectedFolder: camVM.selectedFolderRx.value)
            present(UINavigationController(rootViewController: vc), presentationStyle: .pageSheet, transitionStyle: nil, animated: true)
            
        }).disposed(by: disposeBag)
        
        //선택된 폴더 이름 표시
        camVM.selectedFolderRx.bind { [weak self] folder in
            guard let self else { return }
            UIView.performWithoutAnimation {
                self.storageButton.setTitle(" " + folder.name, for: .normal)
                self.storageButton.layoutIfNeeded()
            }
          
        }.disposed(by: disposeBag)

        
        //설정 버튼
        topMenuView.moreMenuRx.bind { [weak self] in
            guard let self else { return }
            self.moveSettingsView()
        }.disposed(by: disposeBag)
        
        //비율 버튼
        topMenuView.aspectRatioRx.bind { [weak self] aspectRatio in
            guard let self else { return }
            self.enableComponents(false) //이벤트 블락
            self.previewView.blurEffect(true) //블러효과
            
            self.camVM.cameraModel.aspectRatio = aspectRatio
            
            self.setPreviewAspectRatio(aspectRatio: aspectRatio) { [weak self] in
                guard let self else { return }
                self.enableComponents(true)
                self.previewView.blurEffect(false)
            }
        }.disposed(by: disposeBag)
        
        //플래시 버튼
        topMenuView.flashModeRx.bind { [weak self] flashMode in
            self?.camVM.cameraModel.flashMode = flashMode
        }.disposed(by: disposeBag)
        
        
        //카메라 전환 버튼
        topMenuView.cameraPositionRx.bind { [weak self] cameraPosition in
            guard let self else { return }
            self.enableComponents(false) //이벤트 블락
            self.previewView.blurEffect(true) //블러효과
            view.layoutIfNeeded()
            DispatchQueue.main.async {
                self.camVM.cameraModel.updatePosition(position: cameraPosition)
                self.previewView.blurEffect(false) //블러효과
                self.enableComponents(true) //이벤트 블락
            }
            DispatchQueue.main.asyncAfter(wallDeadline: .now() + 0.5) {
                
            }
    
        }.disposed(by: disposeBag)
        
        
        //촬영버튼
        captureButton.addTapGestureRecognizer({ [weak self] in
            guard let self else { return }
            switch captureMode {
            case .photo:
                camVM.capturePhoto() //캡처
            case .video:
                if !camVM.isRecordingVideo.value {
                    camVM.startVideoRecording() //캡처
                    captureButton.setIcon(.stopRecord)
                } else {
                    camVM.stopVideoRecording()
                    captureButton.setIcon(.startRecord)
                }
            }
        })
        
        //캡처시 테두리 효과 색 지정.
        previewView.layer.borderColor = UIColor(resource: .majorLight).cgColor
        
        //뷰어 버튼
        browseButton.rx.tap.bind { [weak self] _ in
            guard let self else { return }
            let nextVC = PhotoListVC()
            nextVC.configure(initialSelectedFolder: camVM.selectedFolderRx.value)
            presentFull(UINavigationController(rootViewController: nextVC), animated: true)
        }.disposed(by: disposeBag)
        
        
        //프리뷰 탭(포커싱)
        previewView.didTapPointRx.withUnretained(self).bind { owner, points in
            owner.camVM.cameraModel.focus(point: points.converted)
        }.disposed(by: disposeBag)
        
        //프리뷰 핀치(배율)
        previewView.didPinchScaleRx.withUnretained(self).bind {owner, scale in
            owner.camVM.cameraModel.zoom(scale: scale)
        }.disposed(by: disposeBag)
        
        //배율 변경 모니터링
        camVM.cameraModel.zoomScaleChangedRx.withUnretained(self).bind { owner, zoomFactor in
            UIView.performWithoutAnimation {
                owner.zoomFactorBtn.setTitle(String(format: "%.1fx", zoomFactor), for: .normal)
                owner.zoomFactorBtn.layoutIfNeeded()
            }
        }
        .disposed(by: disposeBag)
        
        //배율 버튼
        zoomFactorBtn.rx.tap.bind(onNext: { [weak self] _ in
            self?.camVM.cameraModel.zoom(displayFactor: 1.0)
        })
        .disposed(by: disposeBag)
        
        //초점 변경 모니터링
        camVM.cameraModel.focusDevicePointChangedRx.withUnretained(self).bind { owner, focusDevicePoint in
            owner.previewView.showFocusPoint(devicePoint: focusDevicePoint)
        }
        .disposed(by: disposeBag)
        
        camVM.errorOccuredRx.bind { [weak self] error in
            guard let self else { return }
            var message = localizedString(forKey: "N000_2", value: "Please, relaunch the app.")
            


#if DEBUG
            if let captureError = error as? CameraModel.PostCaputreProcessError {
                switch captureError {
                case .avCapturePhotoToData(let log):
                    message = log
                default:
                    break
                }
            }
            #endif
            
            AlertHelper.alertInform(baseVC: self,
                                    title: localizedString(forKey: "N000_1", value: "An error occurred."),
                                    message: message,
                                    confirmCompletion: {})
        }
        .disposed(by: disposeBag)
    
        
        //MARK: 녹화시간
        timeLabel.roundCorners(corners: .allCorners, radius: 6)
        Observable.combineLatest(camVM.isRecordingVideo, camVM.recordingDuration)
            .bind { [weak self] isRecording, duration in
                guard let self else { return }
                timeLabel.isHidden = !isRecording
                timeLabel.text = duration

            }
            .disposed(by: disposeBag)
    }
    
    
    //MARK: - Action Control
    
    ///화면 모든 버튼 활성화/비활성화
    func enableComponents(_ isEnabled: Bool) {
        topMenuView.moreMenuBtn.isEnabled = isEnabled
        topMenuView.aspectRatioBtn.isEnabled = isEnabled
        topMenuView.flashModeBtn.isEnabled = isEnabled
        topMenuView.cameraPositionBtn.isEnabled = isEnabled
        storageButton.isEnabled = isEnabled
        captureButton.isEnabled = isEnabled
        browseButton.isEnabled = isEnabled
        zoomFactorBtn.isEnabled = isEnabled
        previewView.isUserInteractionEnabled = isEnabled
    }
    
    func setPreviewAspectRatio(aspectRatio: AspectRatioType, completion: ( () -> Void )?)  {
        UIView.animate(withDuration: 0.5) { [weak self] in
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
        } completion: { bool in
            completion?()
        }
    }

    @IBAction func photoVideoSegChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            stopCamera()
            captureButton.setIcon(.capturePhoto)
            captureMode = .photo
            startCamera()
        } else {
            stopCamera()
            captureButton.setIcon(.startRecord)
            captureMode = .video
            startCamera()
            
        }
    }
    
    func moveSettingsView() {
        let vc = UIHostingController(rootView: SettingsView())
        vc.modalPresentationStyle = .fullScreen
        present(vc , animated: true)
    }

    //MARK: - Widget이벤트 처리
    @objc func widgetFolderTapped() {
        Self.removeAllViewControllersAbove(self) { [weak self] in
            guard let self else { return }
            let _ = camVM.doWidgetFolderSelectionIfNeeded()
        }
    }
    @objc func widgetSettingTapped() {
        doWidgetOrderIfNeeded()
    }
    @objc func widgetCameraTapped() {
        doWidgetOrderIfNeeded()
    }
    
    func doWidgetOrderIfNeeded(){
        if didOnceAppear, let widgetOrder = WidgetSettingManager.shared.widgetOrder {
            switch widgetOrder {
            case .selectFolder:
                break
            case .camera:
                WidgetSettingManager.shared.widgetOrder = nil
                Self.removeAllViewControllersAbove(self)
            case .setting, .addFolder:
                WidgetSettingManager.shared.widgetOrder = nil
                Self.removeAllViewControllersAbove(self) { [weak self] in
                    guard let self else { return }
                    navigationController?.pushViewController(UIHostingController(rootView: WidgetSettingView()), animated: true)
                }
            }
        }
    }
}

extension UIDevice {
    /// 화면 상단 ‘컷아웃’ 형태
    enum TopCutout {
        case none          // 노치 없음
        case notch         // 노치 (iPhone X ~ 14 / 14 Plus 등)
        case dynamicIsland // 다이내믹 아일랜드 (14 Pro, 15 전 모델 등)
    }

    /// 현재 디바이스가 갖는 상단 컷아웃 유형
    var topCutout: TopCutout {
        // iPad 등은 굳이 조사할 필요 X
        guard UIDevice.current.userInterfaceIdiom == .phone,
              let someWindow = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
            .first?.windows.first(where: { $0.windowLevel == .normal })
        else { return .none }
        
        // 세로 모드에서의 top inset
        let topInset = someWindow.safeAreaInsets.top

        switch topInset {
        case 0..<21:   return .none          // 20pt 이하: 홈버튼 세대
        case 21..<55:  return .notch         // 44~54pt: 일반 노치
        default:       return .dynamicIsland // 55pt 이상: 다이내믹 아일랜드
        }
    }
}

