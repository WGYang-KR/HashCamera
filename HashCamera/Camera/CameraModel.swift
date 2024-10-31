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
    
    ///촬영시작 true, 촬영끝 false
    let isCapturingPhoto: BehaviorRelay<Bool>

    ///카메라 전/후면 설정 set get
    private(set) var position: AVCaptureDevice.Position
    let zoomScaleChangedRx = PublishRelay<CGFloat>()
    let focusDevicePointChangedRx = PublishRelay<CGPoint>()
    
    ///플래시 모두 설정 set get
    var flashMode: AVCaptureDevice.FlashMode
    ///화면비율 설정 set get
    var aspectRatio: AspectRatioType
    ///촬영 완료된 사진 반환 get
    let capturedPhotoData = PublishRelay<Data>()
    ///에러 get
    let errorOccuredRx = PublishRelay<HCError>()
    

    //MARK: - 카메라 시작, 설정, 중지
    //카메라 모델 init
    init(position: AVCaptureDevice.Position,
         flashMode: AVCaptureDevice.FlashMode,
         aspectRatio: AspectRatioType) {
       
        self.isCapturingPhoto = BehaviorRelay(value: false)
        self.position = position
        self.flashMode = flashMode
        self.aspectRatio = aspectRatio
        self.photoOutput = AVCapturePhotoOutput()
        self.captureSession = AVCaptureSession()
        super.init()
        
    }

    
    ///카메라 초기화 - 한번만 호출
    func initCamera() {
        setupSessionOutput()
    }
    ///카메라 시작. global thread에서 실행되는 것 주의
    func startCamera(_ completion: ( () -> Void )? = nil)  {
        DispatchQueue.global(qos: .background).async {[weak self] in
            self?.captureSession.startRunning() // 카메라 세션 시작
            completion?()
        }

    }
    
    
    ///카메라 중지. global thread에서 실행되는 것 주의
    func stopCamera(_ completion: ( () -> Void )? = nil) {
        DispatchQueue.global(qos: .background).async {
            self.captureSession.stopRunning()
            completion?()
        }

    }
    
    private func unbind() {
        disposeBag = DisposeBag()
    }
    
    
    //MARK: - 카메라 설정 기능 처리 함수(private)
  
    
    ///디지털 줌 최대값
    let zoomDigitalMax: CGFloat = 5.0
    var minZoomFactor: CGFloat = 1.0
    var maxZoomFactor: CGFloat = CGFLOAT_MAX
    
    //KVO 키값
    let videoZoomFactorKeyPath = "videoZoomFactor"
    let lensPositionKeyPath = "lensPosition"
    let isAdjustingFocusKeyPath = "adjustingFocus"
    
    ///카메라 전환(전면/후면)
    func updatePosition(position: AVCaptureDevice.Position) {
        self.position = position
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
    func zoom(scale: CGFloat) {
        
        guard let device = videoInput?.device else { return }
       
        var zoomFactor = device.videoZoomFactor
        zoomFactor *= scale
        zoomFactor = max(minZoomFactor, zoomFactor)
        zoomFactor = min(zoomFactor, maxZoomFactor)
    
            
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = zoomFactor
            device.unlockForConfiguration()
        }
        catch {
            hcLog(error.localizedDescription)
        }
        
    }
    
    ///카메라 초점
    func focus(point: CGPoint) {
        
        guard let captureDevice = self.videoInput?.device else { return }
        let focus_x = point.x
        let focus_y = point.y

        hcLog("수동 포커싱: \(focus_x), \(focus_y)")
        
        if (captureDevice.isFocusModeSupported(.autoFocus) && captureDevice.isFocusPointOfInterestSupported) {
            do {
                try captureDevice.lockForConfiguration()
                captureDevice.focusPointOfInterest = CGPoint(x: focus_x, y: focus_y)
                captureDevice.focusMode = .continuousAutoFocus
              
                
                if (captureDevice.isExposureModeSupported(.autoExpose) && captureDevice.isExposurePointOfInterestSupported) {
                    captureDevice.exposurePointOfInterest = CGPoint(x: focus_x, y: focus_y);
                    captureDevice.exposureMode = .continuousAutoExposure
                  
                }
                
                captureDevice.unlockForConfiguration()
            } catch {
                hcLog("\(error) :: \(error.localizedDescription)")
            }
        }
        
    }
    
    ///기기에서 사용가능한 최상의 카메라 장치를 반환한다.
    private func bestDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let deviceTypes: [AVCaptureDevice.DeviceType] = [.builtInTrueDepthCamera,
                                                         .builtInTripleCamera,
                                                         .builtInDualWideCamera,
                                                         .builtInDualCamera,
                                                         .builtInWideAngleCamera,
                                                         .builtInUltraWideCamera,
                                                         .builtInTelephotoCamera]
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes,
                                                                mediaType: .video,
                                                                position: position)
        let devices = discoverySession.devices
        hcLog("카메라(position:\(position) 장치 목록:\n\(devices)")
        
        return devices.first
        
    }

    ///position에 맞게 카메라 디바이스를 설정한다.
    private func setupSessionInput() {
   
        guard let device = bestDevice(position: self.position)
        else {
            hcLog("사용할 수 있는 카메라가 없음")
            return
        }
        
        for input in captureSession.inputs {
            
            // KVO 옵저버 제거
            if let device = (input as? AVCaptureDeviceInput)?.device{
                device.removeObserver(self, forKeyPath: videoZoomFactorKeyPath)
                //TODO: 초점 변경 위치 모니터링
//                device.removeObserver(self, forKeyPath: lensPositionKeyPath)
//                device.removeObserver(self, forKeyPath: isAdjustingFocusKeyPath)
//                NotificationCenter.default.removeObserver(self, name: AVCaptureDevice.subjectAreaDidChangeNotification, object: device)
            }
        
            captureSession.removeInput(input)
        }
        
        do { // 카메라가 사용 가능하면 세션에 input과 output을 연결
            let videoDeviceInput =  try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
            }
            self.videoInput = videoDeviceInput
            
 
            if let device = self.videoInput?.device {
                
                // 줌 배율 변경 감지를 위한 KVO 설정
                device.addObserver(self, forKeyPath: videoZoomFactorKeyPath, options: [.new, .old], context: nil)
                
                //TODO: 초점 변경 위치 모니터링
//                device.addObserver(self, forKeyPath: lensPositionKeyPath, options: [.new], context: nil)
//                device.addObserver(self, forKeyPath: isAdjustingFocusKeyPath, options: [.new], context: nil)
//                do {
//                    try device.lockForConfiguration()
//                    device.isSubjectAreaChangeMonitoringEnabled = true
//                    device.unlockForConfiguration()
//                } catch {
//                    self.errorOccuredRx.accept(.cameraUnknown)
//                }
//                NotificationCenter.default.addObserver(self, selector: #selector(handleSubjectAreaChange), name: AVCaptureDevice.subjectAreaDidChangeNotification, object: device)
             
                
                
                //TODO: 기기별 min,max 줌 값 설정
                if #available(iOS 18.0, *) {
                    minZoomFactor = device.activeFormat.systemRecommendedVideoZoomRange?.lowerBound ?? 1.0
                    maxZoomFactor = device.activeFormat.systemRecommendedVideoZoomRange?.upperBound ?? 30.0
                } else {
                    minZoomFactor = device.minAvailableVideoZoomFactor
                    maxZoomFactor = CGFloat( Int(Float(device.maxAvailableVideoZoomFactor / 50)) * 10 )
                }
                
                //TODO: 기기별 초기 zoom값
                device.videoZoomFactor = 1.0
                
                do {
                    try device.lockForConfiguration()
                    device.focusPointOfInterest = .init(x: 0.5, y: 0.5)
                } catch {
                    //TODO: 에러처리
                }
                
            }
        
        } catch {
            self.errorOccuredRx.accept(.cameraNoDevice)
        }
        
    }
    
    ///촬영 outupt을 설정한다.
    private func setupSessionOutput() {
        captureSession.beginConfiguration()
        for output in captureSession.outputs {
            captureSession.removeOutput(output)
        }
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            captureSession.sessionPreset = .photo
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.maxPhotoQualityPrioritization = .quality
        } else {
            self.errorOccuredRx.accept(.cameraUnknown)
        }
        captureSession.commitConfiguration()
       
    }
    
    //TODO: 초점 변경 위치 모니터링
//    var lastLensPosition: CGFloat?
//    @objc func handleSubjectAreaChange(notification: Notification) {
//       
//        hcLog("주제 영역 변화")
////        focusChanged()
//    }
//    
//    func focusChanged () {
//        // 현재 초점 포인트과거 초점 포인트를 비교하여 변경되었으면 이벤트 발생시킨다.
//        guard let newFocusDevicePoint = videoInput?.device.focusPointOfInterest else { return }
//        guard let adjustingFocus = videoInput?.device.isAdjustingFocus else { return }
//        focusDevicePointChangedRx.accept(newFocusDevicePoint)
//        
//        hcLog("자동 or 수동 포커싱: \(newFocusDevicePoint)")
//    }
//
    
    // KVO를 통해 줌 배율 변화 모니터링
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == videoZoomFactorKeyPath, let change = change {
//            let oldZoomFactor = change[.oldKey] as? CGFloat ?? 0.0
            let newZoomFactor = change[.newKey] as? CGFloat ?? 0.0
            
            var newZoomScale = newZoomFactor
            if #available(iOS 18.0, *) {
                newZoomScale = newZoomFactor * (videoInput?.device.displayVideoZoomFactorMultiplier ?? 1.0)
            } else {
                newZoomScale = newZoomFactor * 0.5
            }
            
            zoomScaleChangedRx.accept(newZoomScale)
        }
        //TODO: 초점 변경 위치 모니터링
//        else if keyPath == lensPositionKeyPath, let change {
//            let newLensPosition = change[.newKey] as? CGFloat ?? 0.0
//            
//            if let lastLensPosition, abs(newLensPosition - lastLensPosition) < 0.1 {
//                return
//            }
//            
//            lastLensPosition = newLensPosition
////            hcLog("렌즈위치변화: \(newLensPosition)")
////            focusChanged()
//        } else if keyPath == isAdjustingFocusKeyPath, let change {
//            let newIsAdjustingFocus = change[.newKey] as? Bool ?? false
//            hcLog("New isAdjustingFocus: \(newIsAdjustingFocus)")
//            
//            if newIsAdjustingFocus {
//                focusChanged()
//              
//            }
//        }
//             
    }
    

    //MARK: - 사진 촬영
    ///사진 촬영. 사진촬영이 완료되면 capturedPhotoData로 결과값을 방출한다.
    func capturePhoto() {
        hcLog("start")
        // 사진 옵션 세팅
        isCapturingPhoto.accept(true)
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.flashMode = self.flashMode
        self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
      
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
        
        let photoData = cropAVPhotoData(photo, aspectRatio: self.aspectRatio.cgFloat)
        self.capturedPhotoData.accept(photoData)
        isCapturingPhoto.accept(false)
        hcLog("end")
        
        
    }
    
    //MARK: 사진 비율 처리
    //기존 Exif 유지하면서, 비율처리된 이미지로 교체
    private func cropAVPhotoData(_ data: AVCapturePhoto, aspectRatio: CGFloat) -> Data {
        hcLog("start")
        guard let originalPhotoData = data.fileDataRepresentation() else { fatalError()}
        guard let croppedImage =  UIImage(data: originalPhotoData)?.crop(aspectRatio: aspectRatio) else { fatalError()}
        
        var croppedImageData: Data?
        switch CameraSetting.photoFileFormat {
        case .heif:
            croppedImageData = croppedImage.heic(compressionQuality: 1.0)
        case .jpeg:
            croppedImageData = croppedImage.jpegData(compressionQuality: 1.0)
        }
        guard let croppedImageData else { fatalError()}
        let resultPhotoData: NSMutableData = NSMutableData(data: croppedImageData)
        guard let originalImageSource = CGImageSourceCreateWithData(originalPhotoData as CFData, nil) else { fatalError()}
        guard let croppedImageSource = CGImageSourceCreateWithData(croppedImageData as CFData, nil) else { fatalError()}
        
        guard let uti: CFString = CGImageSourceGetType(croppedImageSource) else { fatalError()}
        
        guard let destination: CGImageDestination = CGImageDestinationCreateWithData(resultPhotoData as CFMutableData, uti, 1, nil) else { fatalError()}
        guard let cfImageProperties = CGImageSourceCopyPropertiesAtIndex(originalImageSource, 0, nil) else { fatalError() }
        let imageProperties = cfImageProperties as NSDictionary
        let mutable: NSMutableDictionary = imageProperties.mutableCopy() as! NSMutableDictionary
        
        //MARK: crop된 이미지의 픽셀, DPI 등 정보 갱신 필요..
        let EXIFDictionary: NSMutableDictionary = (mutable[kCGImagePropertyExifDictionary as String] as? NSMutableDictionary)!
//        dump(EXIFDictionary)
        EXIFDictionary[kCGImagePropertyExifUserComment as String] = "type:photo"
        mutable[kCGImagePropertyExifDictionary as String] = EXIFDictionary
        
        CGImageDestinationAddImageFromSource(destination, croppedImageSource, 0, mutable as CFDictionary)
        CGImageDestinationFinalize(destination)
        hcLog("end")
        return resultPhotoData as Data
    }
    
    //MARK: -
 
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
    
    var cgImageOrientation: CGImagePropertyOrientation { .init(imageOrientation) }

    
    func heic(compressionQuality: CGFloat = 1) -> Data? {
        guard
            let mutableData = CFDataCreateMutable(nil, 0),
            let destination = CGImageDestinationCreateWithData(mutableData, UTType.heic.identifier as CFString, 1, nil),
            let cgImage = cgImage
        else { return nil }
        CGImageDestinationAddImage(destination, cgImage, [kCGImageDestinationLossyCompressionQuality: compressionQuality, kCGImagePropertyOrientation: cgImageOrientation.rawValue] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return mutableData as Data
    }
    
}

extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
            case .up: self = .up
            case .upMirrored: self = .upMirrored
            case .down: self = .down
            case .downMirrored: self = .downMirrored
            case .left: self = .left
            case .leftMirrored: self = .leftMirrored
            case .right: self = .right
            case .rightMirrored: self = .rightMirrored
        @unknown default:
            fatalError()
        }
    }
}
