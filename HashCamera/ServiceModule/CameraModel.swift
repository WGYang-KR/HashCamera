//
//  CameraModel.swift
//  HashCamera
//
//  Created by WG-MacHome on 10/31/23.
//

import UIKit
import AVFoundation
import CoreMotion
import RxSwift
import RxRelay

class CameraModel {
    
    
    
    var position: AVCaptureDevice.Position
    let captureSession: AVCaptureSession
    let videoInput: AVCaptureDeviceInput
    
    init() {
        self.position = .unspecified
        self.captureSession = AVCaptureSession()
        
    }
    
    func prepare() {
        guard let videoInput
        self.videoInput
    }
    
    func setInput(session: AVCaptureSession, ) {
        
    }
    
    
    ///기기에서 사용가능한 최상의 카메라 장치를 반환한다.
    private func bestDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let deviceTypes: [AVCaptureDevice.DeviceType] = [.builtInTrueDepthCamera,
                                                             .builtInTripleCamera,
                                                             .builtInDualCamera,
                                                             .builtInWideAngleCamera]
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes,
                                                                mediaType: .video,
                                                                position: position)
        let devices = discoverySession.devices
        hcLog("카메라(position:\(position) 장치 목록: \(devices)")
        
        return devices.first
    
    }
}
