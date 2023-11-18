//
//  CameraPreviewView.swift
//  HashCamera
//
//  Created by WG-Yang on 11/3/23.
//

import UIKit
import AVFoundation
import SnapKit

class CameraPreviewView: UIView {

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
