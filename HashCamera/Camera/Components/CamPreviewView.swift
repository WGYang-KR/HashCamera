//
//  CameraPreviewView.swift
//  HashCamera
//
//  Created by WG-Yang on 11/3/23.
//

import UIKit
import AVFoundation
import SnapKit
import RxSwift
import RxRelay

class CameraPreviewView: UIView {

    var disposeBag = DisposeBag()
    
    ///카메라 프리뷰의 한 지점을 나타내는 구조체
    struct CaptureDevicePreviewPoints{
        let original: CGPoint
        ///AVFoundation 용 좌표
        let converted: CGPoint
    }
    
    ///카메라 프리뷰가 탭되는 위치 이벤트를 방출한다.
    let didTapPointRx = PublishRelay<CaptureDevicePreviewPoints>()
    let didPinchScaleRx = PublishRelay<CGFloat>()
                                      
                                      
    let blurEffectView: UIView = {
        let viewBlurEffect = UIVisualEffectView()
        //Blur Effect는 .light 외에도 .dark, .regular 등이 있으니 적용해보세요!
        viewBlurEffect.effect = UIBlurEffect(style: .light)
        
        return viewBlurEffect
    }()
    
    // Use AVCaptureVideoPreviewLayer as the view's backing layer.
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
    
    var session: AVCaptureSession? {
        willSet {
            previewLayer.session = newValue
            previewLayer.connection?.videoOrientation = .portrait
        }
    }

    init(session: AVCaptureSession?) {
        super.init(frame: .zero)
        initPreviewLayer()
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initPreviewLayer()
        initView()
    }
    
    func initPreviewLayer() {
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.cornerRadius = 0
        previewLayer.backgroundColor = UIColor.clear.cgColor
        
        clipsToBounds = true
    }
     
    func initView() {
        addSubview(blurEffectView)
        blurEffectView.isHidden = true
        blurEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        //탭 이벤트 연결
        self.rx.tapGesture().when(.recognized)
            .bind { [weak self] recognizer in
                
                guard let self else { return }
                
                let location = recognizer.location(in: self)
                didTapPointRx.accept(.init(original: location,
                                           converted: previewLayer.captureDevicePointConverted(fromLayerPoint: location)))
                
            }.disposed(by: disposeBag)
        
        self.rx.pinchGesture().when(.changed)
            .bind { [weak self] recognizer in
                guard let self else { return }
                didPinchScaleRx.accept(recognizer.scale)
                recognizer.scale = 1
            }.disposed(by: disposeBag)
        
    }
    
    func borderEffect() {
        UIView.animate(withDuration: 0.1) {
            self.layer.borderWidth = 2
            
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            UIView.animate(withDuration: 0.1) {
                self.layer.borderWidth = 0
            }
        })
    }
    

    func blurEffect(_ applies: Bool) {
            blurEffectView.isHidden = !applies
    }
    
    
}
