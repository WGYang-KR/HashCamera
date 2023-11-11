//
//  CameraModel.swift
//  HashCamera
//
//  Created by WG-MacHome on 10/31/23.
//

import UIKit
import AVFoundation
import RxSwift
import RxRelay


//사진 촬영을 제외하고는 rx를 이용해서 get, set
class CameraModel: NSObject, AVCapturePhotoCaptureDelegate {
    
    let captureSession: AVCaptureSession
    private var videoInput: AVCaptureDeviceInput?
    private let photoOutput: AVCapturePhotoOutput
    private var disposeBag = DisposeBag()
    
    ///카메라 시작, 전후면 전환 중 여부 get
    let isLoading: BehaviorRelay<Bool>

    ///카메라 전/후면 설정 set get
    let position: BehaviorRelay<AVCaptureDevice.Position>
    let zoomFactor: BehaviorRelay<CGFloat>
    ///플래시 모두 설정 set get
    let flashMode: BehaviorRelay<AVCaptureDevice.FlashMode>
    ///화면비율 설정 set get
    let aspectRatio: BehaviorRelay<AspectRatioType>
    ///촬영 완료된 사진 반환 get
    let capturedPhotoData = PublishSubject<Data>()
    ///에러 get
    let error = PublishRelay<HCError>()
    
    
    //MARK: - 카메라 시작, 설정, 중지
//    private override init() {
//        super.init()
//    }
//    
    init(position: AVCaptureDevice.Position,
         flashMode: AVCaptureDevice.FlashMode,
         aspectRatio: AspectRatioType,
         fileType: PhotoFileType) {
       
        self.isLoading = BehaviorRelay(value: true)
        self.position = BehaviorRelay(value: position)
        self.zoomFactor = BehaviorRelay(value: 1.0)
        self.flashMode = BehaviorRelay(value: flashMode)
        self.aspectRatio = BehaviorRelay(value: aspectRatio)
        self.photoOutput = AVCapturePhotoOutput()
        self.captureSession = AVCaptureSession()
        super.init()
        
    }

    ///카메라 시작
    func startCamera() async -> Bool {
        bind()
        return true
    }
    
    ///카메라 중지
    func stopCamera() async -> Bool {
        DispatchQueue.global(qos: .background).async {
            self.captureSession.stopRunning()
        }
        unbind()
        return true
        
    }
    
    
    private func bind() {

        position.subscribe(onNext: { [weak self] position in
            self?.isLoading.accept(true)
            self?.updatePosition(position: position)
            DispatchQueue.global(qos: .background).async {
                self?.captureSession.startRunning() // 세션 시작
                self?.isLoading.accept(false)
            }
        }).disposed(by: disposeBag)
        
        zoomFactor.subscribe(onNext:  { [weak self] value in
            self?.zoom(value)
        }).disposed(by: disposeBag)
        
    }
    
    private func unbind() {
        disposeBag = DisposeBag()
    }
    
    
    //MARK: - 카메라 설정 기능 처리 함수(private)
    ///카메라 전환(전면/후면)
    private func updatePosition(position: AVCaptureDevice.Position) {
        captureSession.beginConfiguration()
        setupSessionInput()
        
        if let connection =
            self.photoOutput.connection(with: .video) {
            if connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .auto
            }
        }
        captureSession.commitConfiguration()
    }
    
    
    ///카메라 줌
    private func zoom(_ zoom: CGFloat) {
        
        guard let device = videoInput?.device else { return }
        let factor = zoom < 1 ? 1 : zoom
        
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = factor
            device.unlockForConfiguration()
        }
        catch {
            print(error.localizedDescription)
        }
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
    
    ///position에 맞게 카메라 디바이스를 설정한다.
    private func setupSessionInput() {
        
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }
        guard let device = bestDevice(position: self.position.value)
        else {
            print("사용할 수 있는 카메라가 없음")
            return
        }
        
        do { // 카메라가 사용 가능하면 세션에 input과 output을 연결
            let videoDeviceInput =  try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
            }
            self.videoInput = videoDeviceInput
            
        } catch {
            self.error.accept(.cameraNoDevice)
        }
        
    }
    
    ///촬영 outupt을 설정한다.
    private func setupSessionOutput() {
        
        for output in captureSession.outputs {
            captureSession.removeOutput(output)
        }
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            captureSession.sessionPreset = .photo
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.maxPhotoQualityPrioritization = .quality
        } else {
            self.error.accept(.cameraUnknown)
        }
       
    }
    
    
    //MARK: - 사진 촬영
    ///사진 촬영
    func capture() async -> Bool{
        // 사진 옵션 세팅
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.flashMode = self.flashMode.value
        self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
        print("[Camera]: Photo's taken")
        return true
        
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        AudioServicesDisposeSystemSoundID(1108)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        AudioServicesDisposeSystemSoundID(1108)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        let photoData = cropAVPhotoData(photo, aspectRatio: self.aspectRatio.value.cgFloat)
        self.capturedPhotoData.onNext(photoData)
    }
    
    //MARK: 사진 비율 처리
    //기존 Exif 유지하면서, 비율처리된 이미지로 교체
    private func cropAVPhotoData(_ data: AVCapturePhoto, aspectRatio: CGFloat) -> Data {
        guard let originalPhotoData = data.fileDataRepresentation() else { fatalError()}
        guard let croppedImage =  UIImage(data: originalPhotoData)?.crop(aspectRatio: aspectRatio) else { fatalError()}
        
        guard let croppedImageData = croppedImage.jpegData(compressionQuality: 1.0) else { fatalError()}
        
        let resultPhotoData: NSMutableData = NSMutableData(data: croppedImageData)
        guard let originalImageSource = CGImageSourceCreateWithData(originalPhotoData as CFData, nil) else { fatalError()}
        guard let croppedImageSource = CGImageSourceCreateWithData(croppedImageData as CFData, nil) else { fatalError()}
        guard let uti: CFString = CGImageSourceGetType(originalImageSource) else { fatalError()}
        guard let destination: CGImageDestination = CGImageDestinationCreateWithData(resultPhotoData as CFMutableData, uti, 1, nil) else { fatalError()}
        guard let cfImageProperties = CGImageSourceCopyPropertiesAtIndex(originalImageSource, 0, nil) else { fatalError() }
        let imageProperties = cfImageProperties as NSDictionary
        let mutable: NSMutableDictionary = imageProperties.mutableCopy() as! NSMutableDictionary
        
        //MARK: crop된 이미지의 픽셀, DPI 등 정보 갱신 필요..
        let EXIFDictionary: NSMutableDictionary = (mutable[kCGImagePropertyExifDictionary as String] as? NSMutableDictionary)!
        dump(EXIFDictionary)
        EXIFDictionary[kCGImagePropertyExifUserComment as String] = "type:photo"
        mutable[kCGImagePropertyExifDictionary as String] = EXIFDictionary
        
        CGImageDestinationAddImageFromSource(destination, croppedImageSource, 0, mutable as CFDictionary)
        CGImageDestinationFinalize(destination)
        
        return resultPhotoData as Data
    }
    
    
}

extension UIImage {
    
    /// 이미지 자르기
    /// - Parameter aspectRatio: 가로를 세로로 나눈 값
    /// - Returns: 중앙 기준으로 비율에 맞추어 이미지를 자르고, 남는 이미지는 버린다.
    func crop(aspectRatio: CGFloat) -> UIImage {
        let image = self
        let originalAspectRatio = image.size.width / image.size.height
        
        var newImagesize = image.size
        
        if originalAspectRatio > aspectRatio {
            newImagesize.width = image.size.height * aspectRatio
        } else if originalAspectRatio < aspectRatio {
            newImagesize.height = image.size.width / aspectRatio
        } else {
            return image
        }
        
        //cgImage는 가로로 길게 입력되므로 height width 바꾸어생각해야함.
        let center = CGPoint(x: image.size.height/2, y: image.size.width/2)
        let origin = CGPoint(x: center.x - newImagesize.height/2, y: center.y - newImagesize.width/2)
        
        let cgCroppedImage = image.cgImage!.cropping(to: CGRect(origin: origin, size: CGSize(width: newImagesize.height, height: newImagesize.width)))!
        let croppedImage = UIImage(cgImage: cgCroppedImage, scale: image.scale, orientation: image.imageOrientation)
        
        return croppedImage
    }
}
