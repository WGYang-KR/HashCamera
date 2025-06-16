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
import FirebaseCrashlytics

//사진 촬영을 제외하고는 rx를 이용해서 get, set
class CameraModel: NSObject, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {
    
    let captureSession: AVCaptureSession
    private var videoInput: AVCaptureDeviceInput?
    private let photoOutput: AVCapturePhotoOutput
    private let movieOutput = AVCaptureMovieFileOutput() // 🔹추가
    private var disposeBag = DisposeBag()
    
    ///촬영시작 true, 촬영끝 false
    let isCapturingPhoto: BehaviorRelay<Bool>
    let isRecordingVideo: BehaviorRelay<Bool> = BehaviorRelay(value: false) // 🔹추가

    ///카메라 전/후면 설정 set get
    private(set) var position: AVCaptureDevice.Position
    
    
    ///카메라 줌 배율 변경Rx
    let zoomScaleChangedRx = PublishRelay<CGFloat>()
    ///카메라의 1x 줌에 해당하는 Factor
    var defaultZoomDeviceFactor: CGFloat = 1.0
    ///최대 줌 제한
    var maxZoomDeviceFactor: CGFloat = 4.0
    ///화면에 표시되는 카메라 줌 단위로 변환할 때 곱하는 숫자
    var displayZoomFactorMultiplier: CGFloat = 1.0
    
    let focusDevicePointChangedRx = PublishRelay<CGPoint>()
    
    ///플래시 모두 설정 set get
    var flashMode: AVCaptureDevice.FlashMode
    ///화면비율 설정 set get
    var aspectRatio: AspectRatioType
    ///촬영 완료된 사진 반환 get
    let capturedPhotoData = PublishRelay<Result<Data,PostCaputreProcessError>>()
    ///촬영 완료된 비디오 반환
    let capturedVideoURL = PublishRelay<Result<URL, Error>>() // 🔹추가
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
    
    //MARK: 카메라 줌
    ///카메라 줌 기본값, 최소값, 최대값 지정
    func setupZoom() {
        
        guard let device = videoInput?.device else { return }
        
        //virtualDeviceSwitchOverVideoZoomFactors의 첫번째 값을 1배율로 가정. 없으면 1.0은 1.0
        if let firstSwitchFactor = device.virtualDeviceSwitchOverVideoZoomFactors.first {
            defaultZoomDeviceFactor = CGFloat(firstSwitchFactor.floatValue)
            //이게 만약 2라면 모든 배율 표시는 zoomFactor에 1/2를 하는 식으로 표시
            displayZoomFactorMultiplier = 1 / defaultZoomDeviceFactor
        } else {
            defaultZoomDeviceFactor = 1.0
            displayZoomFactorMultiplier = 1.0
        }
        
        //virtualDeviceSwitchOverVideoZoomFactors의 마지막 배율에서 3배 까지를 max로 지정
        if let lastSwitchFactor = device.virtualDeviceSwitchOverVideoZoomFactors.last {
            maxZoomFactor = CGFloat(lastSwitchFactor.floatValue * 3.0)
        } else {
            maxZoomFactor = defaultZoomDeviceFactor * 3.0
        }

        //Zoom 기본값으로 설정
        device.videoZoomFactor = defaultZoomDeviceFactor
    }
    
    ///카메라 줌 키우기, 줄이기
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
    
    ///특정 줌으로 설정
    func zoom(displayFactor: CGFloat) {
        guard let device = videoInput?.device else { return }
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = displayFactor / displayZoomFactorMultiplier
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
                setupZoom()
                
                do {
                 
                    if (device.isFocusPointOfInterestSupported) {
                        try device.lockForConfiguration()
                        device.focusPointOfInterest = .init(x: 0.5, y: 0.5)
                        device.unlockForConfiguration()
                    }
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
        
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
            captureSession.sessionPreset = .high // or .hd1920x1080 etc.
        } else {
            self.errorOccuredRx.accept(.cameraUnknown)
        }
        captureSession.commitConfiguration()
       
    }
    
    // KVO를 통해 줌 배율 변화 모니터링
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == videoZoomFactorKeyPath, let change = change {
            let newZoomFactor = change[.newKey] as? CGFloat ?? 0.0
            zoomScaleChangedRx.accept( newZoomFactor * displayZoomFactorMultiplier)
        }
    }
    

    //MARK: - 사진 촬영
    ///사진 촬영. 사진촬영이 완료되면 capturedPhotoData로 결과값을 방출한다.
    func capturePhoto() {
        hcLog("카메라 촬영 시작")
        // 사진 옵션 세팅
        isCapturingPhoto.accept(true)
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.flashMode = self.flashMode
        
        hcLog("UIDevice.current.orientation: \(UIDevice.current.orientation)")
        // 디바이스의 현재 orientation을 가져와 설정
        //TODO: 17.0 부분 변환 안맞음
//        if #available(iOS 17.0, *) {
//            if let connection = photoOutput.connection(with: .video) {
//                switch UIDevice.current.orientation {
//                case .portrait:
//                    connection.videoRotationAngle = 0
//                case .landscapeLeft:
//                    connection.videoRotationAngle = 90
//                case .landscapeRight:
//                    connection.videoRotationAngle = 270
//                case .portraitUpsideDown:
//                    connection.videoRotationAngle = 180
//                default:
//                    connection.videoRotationAngle = 0
//                }
//            }
//        } else {
            if let connection = photoOutput.connection(with: .video) {
                let deviceOrientation = UIDevice.current.orientation
                connection.videoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation) ?? .portrait
            }
//        }
        
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
        
        let photoDataResult = cropAVPhotoData(photo, aspectRatio: self.aspectRatio.cgFloat)
        switch photoDataResult {
        case .success(let photoData):
            self.capturedPhotoData.accept(.success(photoData))
        case .failure(let error):
            self.capturedPhotoData.accept(.failure(error))
        }
        isCapturingPhoto.accept(false)
        hcLog("카메라 촬영 프로세스 완료")
        
    }
    
    // MARK: - 비디오 촬영
    func startRecording() {
        guard !movieOutput.isRecording else { return }
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let outputFileURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
        if let connection = movieOutput.connection(with: .video),
           connection.isVideoOrientationSupported {
            let deviceOrientation = UIDevice.current.orientation
            connection.videoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation) ?? .portrait
        }
        movieOutput.startRecording(to: outputFileURL, recordingDelegate: self)
        isRecordingVideo.accept(true)
    }
    
    func stopRecording() {
        guard movieOutput.isRecording else { return }
        movieOutput.stopRecording()
        isRecordingVideo.accept(false)
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            hcLog("비디오 녹화 에러: \(error.localizedDescription)")
            capturedVideoURL.accept(.failure(error))
        } else {
            capturedVideoURL.accept(.success(outputFileURL))
        }
    }
    
    
    //MARK: 사진 처리
    
    //기존 Exif 유지하면서, 비율처리된 이미지로 교체
    private func cropAVPhotoData(_ avCapturePhoto: AVCapturePhoto, aspectRatio: CGFloat) -> Result<Data, PostCaputreProcessError> {
        hcLog("변환 시작")
        
   //에러 파악위한 상태 메시지 만들기
        var statusMsg = ""
        statusMsg += "avCapturePhoto: \(avCapturePhoto)\n"
        statusMsg += "videoInput: \(String(describing: videoInput))\n"
   
        var photoOutputDump = ""
        dump(photoOutput, to: &photoOutputDump)
        statusMsg += "photoOutput: \(photoOutputDump)\n"
        
        statusMsg += "captureSession isRunnig: \(captureSession.isRunning)\n"
        if let videoInput {
            statusMsg += "captureSession containsInput: \(captureSession.inputs.contains(videoInput))\n"
        } else {
            statusMsg += "captureSession containsInput: nil\n"
        }
        statusMsg += "captureSession containsOutput: \(captureSession.outputs.contains(photoOutput))\n"
        hcLog(statusMsg)
        
        //avCapturePhoto의 이미지 Data를 추출
        guard let originalPhotoData = avCapturePhoto.fileDataRepresentation() else {
            let error = NSError.init(domain: "PostCaputreProcessError.avCapturePhotoToData",
                                     code: -0001,
                                     userInfo: [
                                        NSLocalizedDescriptionKey: "PostCaputreProcessError.avCapturePhotoToData",
                                        NSLocalizedFailureReasonErrorKey: statusMsg
                                     ])
            
            Crashlytics.crashlytics().record(error: error)
            
            return .failure(.avCapturePhotoToData(log: statusMsg))}
        
        
        //UIImage로 변환하여 자르기
        guard let originUIImage = UIImage(data: originalPhotoData) else { return .failure(.dataToUIImage) }
        guard let originCGImage = originUIImage.cgImage else { return .failure(.uiImageToCGImage)}
        guard let croppedCGImgage = try? originCGImage.crop(aspectRatio: aspectRatio) else { return .failure(.cropCGImage)}
        
        //위에서 저장한 방향 정보와 함께 uiImage로 변환
        let croppedImage = UIImage(cgImage: croppedCGImgage, scale: originUIImage.scale, orientation: originUIImage.imageOrientation)

        //파일 포맷에 맞춰 Data로 변환
        var croppedImageData: Data?
        switch CameraSetting.photoFileFormat {
        case .heic:
            croppedImageData = croppedImage.heic(compressionQuality: 1.0)
        case .jpeg:
            croppedImageData = croppedImage.jpegData(compressionQuality: 1.0)
        }
        guard let croppedImageData else { return .failure(.uiImageToData) }
        
        //저장할 이미지 데이터
        let resultPhotoData: NSMutableData = NSMutableData(data: croppedImageData)
        //저장할 이미지를 버퍼한다
        guard let originalImageSource = CGImageSourceCreateWithData(originalPhotoData as CFData, nil) else { return .failure(.createOriginImageSource)}
        //원본 이미지를 버퍼한다
        guard let croppedImageSource = CGImageSourceCreateWithData(croppedImageData as CFData, nil) else { return .failure(.createCroppedImageSource)}
        
        //저장할 이미지의 파일형식을 가져온다
        guard let uti: CFString = CGImageSourceGetType(croppedImageSource) else { return .failure(.getSourceType)}
        
        //이미지 저장 세션을 연다.
        guard let destination: CGImageDestination = CGImageDestinationCreateWithData(resultPhotoData as CFMutableData, uti, 1, nil) else { return .failure(.createImageDest)}
        
        //원본 이미지 exif 속성을 가져온다
        guard let originCFProperties = CGImageSourceCopyPropertiesAtIndex(originalImageSource, 0, nil) else { return .failure(.cfProperties) }
        guard let originMutableProperties: NSMutableDictionary = (originCFProperties as NSDictionary).mutableCopy() as? NSMutableDictionary else { return .failure(.cfPropertiesDictionary) }
        guard let nsEXIFDictionary: NSMutableDictionary = (originMutableProperties[kCGImagePropertyExifDictionary as String] as? NSMutableDictionary) else { return .failure(.nsEXIFDictionary)}
        
        //crop된 이미지의 픽셀 정보 exif 갱신
        nsEXIFDictionary[kCGImagePropertyExifUserComment as String] = "type:photo"
        nsEXIFDictionary[kCGImagePropertyExifPixelXDimension as String] =  croppedImage.size.width
        nsEXIFDictionary[kCGImagePropertyExifPixelYDimension as String] = croppedImage.size.height
        //변경된 exif 속성을 복사한다
        originMutableProperties[kCGImagePropertyExifDictionary as String] = nsEXIFDictionary
        
        CGImageDestinationAddImageFromSource(destination, croppedImageSource, 0, originMutableProperties as CFDictionary)
        CGImageDestinationFinalize(destination)
        hcLog("변환 종료")
        return .success(resultPhotoData as Data)
    }
    enum PostCaputreProcessError: Error {
        case avCapturePhotoToData(log: String)
        case dataToUIImage
        case uiImageToCGImage
        case cropCGImage
        case cgImageToUIImage
        case uiImageToData
        case createOriginImageSource
        case createCroppedImageSource
        case getSourceType
        case createImageDest
        case cfProperties
        case cfPropertiesDictionary
        case nsEXIFDictionary
        
    }
    
    //MARK: -
 
}

extension CGImage {
    /// 이미지 자르기
    /// - Parameter aspectRatio: 가로를 세로로 나눈 값
    /// - Returns: 중앙 기준으로 비율에 맞추어 이미지를 자르고, 남는 이미지는 버린다.
    func crop(aspectRatio: CGFloat) throws -> CGImage {
        //cgImage는 가로로 길게 입력되는 점 유의
        let cgImage = self

        let originWidth: CGFloat = CGFloat(cgImage.width)
        let originHeight: CGFloat = CGFloat(cgImage.height)
        let originalAspectRatio = originWidth / originHeight
        
        var newImagesize =  CGSize.zero
        if aspectRatio > originalAspectRatio {
            newImagesize.width = originWidth
            newImagesize.height = originWidth / aspectRatio
        } else if aspectRatio < originalAspectRatio {
            newImagesize.width = originHeight * aspectRatio
            newImagesize.height = originHeight

        } else {
            return self
        }
        
      
        let center = CGPoint(x: originWidth/2, y: originHeight/2)
        let origin = CGPoint(x: center.x - newImagesize.width/2, y: center.y - newImagesize.height/2)
        
        let cgCroppedImage = cgImage.cropping(to: CGRect(origin: origin, size: CGSize(width: newImagesize.width, height: newImagesize.height)))
        guard let cgCroppedImage else { throw CGImageCropError.conversion }
        return cgCroppedImage
    }
    enum CGImageCropError: Error {
        case conversion
    }
}
extension UIImage {
    
    var cgImageOrientation: CGImagePropertyOrientation { .init(self.imageOrientation) }

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

extension AVCaptureVideoOrientation {
    init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait:
            self = .portrait
        case .portraitUpsideDown:
            self = .portraitUpsideDown
        case .landscapeLeft:
            self = .landscapeRight
        case .landscapeRight:
            self = .landscapeLeft
        default:
            return nil
        }
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
            self = .up
        }
    }
}

extension UIImage.Orientation {
    init?(_ cgOrientation: CGImagePropertyOrientation) {
        switch cgOrientation {
            case .up: self = .up
            case .upMirrored: self = .upMirrored
            case .down: self = .down
            case .downMirrored: self = .downMirrored
            case .left: self = .left
            case .leftMirrored: self = .leftMirrored
            case .right: self = .right
            case .rightMirrored: self = .rightMirrored
        @unknown default:
            return nil
        }
    }
}
