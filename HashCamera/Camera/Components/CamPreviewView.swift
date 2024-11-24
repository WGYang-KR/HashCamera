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
    
    var overlayView: UIView!
    
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
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }
     
    private func initView() {
        
        //init PreviewLayer
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.cornerRadius = 0
        previewLayer.backgroundColor = UIColor.clear.cgColor
        
        clipsToBounds = true
        
        //init View
        addSubview(blurEffectView)
        blurEffectView.isHidden = true
        blurEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        overlayView = UIView(frame: .zero)
        overlayView.backgroundColor = UIColor.white
        overlayView.alpha = 0.0
        addSubview(overlayView)
        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        //탭 이벤트 연결
        self.rx.tapGesture().when(.recognized)
            .bind { [weak self] recognizer in
                
                guard let self else { return }
                
                let location = recognizer.location(in: self)
        
                showFocusView(location)
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
    
    func opaqueEffect() {
          UIView.animate(withDuration: 0.1, animations: {
              self.overlayView.alpha = 0.6
          }) { _ in
              UIView.animate(withDuration: 0.1, animations: {
                  self.overlayView.alpha = 0.0
              })
          }
    }
    

    func blurEffect(_ applies: Bool) {
            blurEffectView.isHidden = !applies
    }
    
    func showFocusPoint(devicePoint: CGPoint) {
        let foucsPoint = previewLayer.layerPointConverted(fromCaptureDevicePoint: devicePoint)
        showFocusView(foucsPoint)
    }
    
    
    ///해당위치에 포커스를 나타내는 뷰를 띄웠다가 사라지게 한다.
    private func showFocusView(_ point: CGPoint) {
        
        let focusView = newFocusView()
        let convertedPoint = CGPoint(x: point.x - focusView.bounds.width / 2,
                                     y: point.y - focusView.bounds.height / 2)
        
        self.addSubview(focusView)
        focusView.frame = CGRect(origin: convertedPoint, size: focusView.frame.size)
        self.bringSubviewToFront(focusView)
    
        Task { [weak self] in
            guard let self else { return }
            UIView.transition(with: self, duration: 0.5, options: [.transitionCrossDissolve]) {
                focusView.removeFromSuperview()
            }
        }
        
        ///포커스 위치 나타내는 뷰
        func newFocusView() -> UIView {
            let view = UIView()
            view.backgroundColor = .clear
            view.frame = .init(origin: .zero, size: CGSize(width: 80, height: 80))
            view.layer.borderWidth = 1
            view.layer.borderUIColor = UIColor.majorDark
            
            return view
        }
        
    }
    
}
