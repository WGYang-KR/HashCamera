//
//  CameraPreviewView.swift
//  HashCamera
//
//  Created by WG-Yang on 11/3/23.
//

import UIKit
import AVFoundation

class CameraPreviewView: UIView {

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
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initPreviewLayer()
    }
    
    func initPreviewLayer() {
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.cornerRadius = 0
    }
     
}
