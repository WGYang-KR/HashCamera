//
//  CamVM.swift
//  HashCamera
//
//  Created by WG-MacHome on 11/16/23.
//

import Foundation
import AVFoundation
import RxSwift
import RxRelay

class CamVM: SelectSaveFolderVCDelegate {

    var disposeBag = DisposeBag()
    
    let cameraModel: CameraModel = CameraModel(position: .back,
                                               flashMode: .off,
                                               aspectRatio: .standard)

    let fileManager = FileManager.default

    ///폴더 목록
    var folderMap: [FolderSectionType: [any FolderModelProtocol]] = [:]
    ///선택된 저장 폴더
    let selectedFolderRx = BehaviorRelay<any FolderModelProtocol>(value: DefaultFolderModel())
    ///사진 저장 포맷
    var photoFileFormat: PhotoFileFormat {
        return CameraSetting.photoFileFormat
    }
    
    ///촬영시 true -> 저장 완료 후 false
    let isCapturingPhoto = BehaviorRelay(value: false)
    let isRecordingVideo = BehaviorRelay(value: false) // 🔹 비디오 녹화 상태 추가
    let errorOccuredRx = PublishRelay<Error>()
    
    let recordingDuration = BehaviorRelay<String>(value: "00:00")
    

    enum FolderSectionType: Int, CaseIterable {
        case defaultFolder
        case local
        case google
    }
    init() {
        initCamera()
        initFolderSelection()
        WidgetSettingManager.shared.startMonitor()
    }

    //MARK: - 카메라, 촬영
    func initCamera() {
        
        ///사진 캡처결과 받아서 저장소에 저장하기 연결
        cameraModel.capturedPhotoData.bind { [weak self] photoDataResult in
            guard let self else { return }
            switch photoDataResult {
            case .success(let photoData):
                let result = savePhoto(photoData: photoData)
                switch result {
                case .success(let url):
                    hcLog("사진저장결과 \(url.lastPathComponent)")
                case .failure(let error):
                    errorOccuredRx.accept(error)
                }
            case .failure(let error):
                errorOccuredRx.accept(error)
            }
            
        }.disposed(by: disposeBag)
        
        // 🔹 비디오 캡처 결과 저장
        cameraModel.capturedVideoURL
            .bind { [weak self] videoRecordResult in
                guard let self else { return }
                switch videoRecordResult {
                case .success(let videoURL):
                    let result = saveVideo(videoURL: videoURL)
                    switch result {
                    case .success(let savedURL):
                        hcLog("🎬 비디오 저장 완료: \(savedURL.lastPathComponent)")
                    case .failure(let error):
                        errorOccuredRx.accept(error)
                    }
                case .failure(let error):
                    errorOccuredRx.accept(error)
                }
                
            }
            .disposed(by: disposeBag)
        
        // 🔹 상태 동기화
        cameraModel.isCapturingPhoto
            .bind(to: isCapturingPhoto)
            .disposed(by: disposeBag)
        
        cameraModel.isRecordingVideo
            .bind(to: isRecordingVideo)
            .disposed(by: disposeBag)
        
        cameraModel.recordingDuration
            .map {  duration -> String in
                let minutes = Int(duration) / 60
                let seconds = Int(duration) % 60
                return String(format: "%02d:%02d", minutes, seconds)
            }
            .bind(to:recordingDuration)
            .disposed(by: disposeBag)
    }

    func stopCamera() {
        //녹화 진행중이면 녹화완료후 카메라를 끝낸다.
        if cameraModel.isRecordingVideo.value {
            cameraModel.capturedVideoURL.asMaybe().subscribe(onDisposed: {
                self.cameraModel.stopCamera()
            })
            .disposed(by: disposeBag)
            
            cameraModel.stopRecording()
        }
        else {
            cameraModel.stopCamera()
        }
    }
    
    
    func capturePhoto() {
        cameraModel.capturePhoto() //촬영 후 결과값은 capturedPhotoData로 수신
    }
    
    // 🔹 비디오 촬영 시작
    func startVideoRecording() {
        cameraModel.startRecording()
    }
    
    // 🔹 비디오 촬영 종료
    func stopVideoRecording() {
        cameraModel.stopRecording()
    }

    
    //MARK: - 저장폴더
    func initFolderSelection() {

        FolderService.shared.folderListUpdatedRx
            .bind { [weak self] updateData in
                //업데이트 이벤트 핸들러
                guard let self else { return }
                guard var localFolderList = folderMap[.local] as? [LocalFolderModel] else { return }
                localFolderList = updateData.newFileList.map{LocalFolderModel(url: $0)}
                switch updateData.changeType {
                    case .initiate:
  
                    if doWidgetFolderSelectionIfNeeded() {
                        hcLog("doWidgetFolderSelectionIfNeeded")
                    }
                    else if let selectedFolder = CameraSetting.selectedFolder {
            
                        if let defaultFolder = selectedFolder as? DefaultFolderModel {
                            selectedFolderRx.accept(defaultFolder)
                        }
                        else if let localFolder = selectedFolder as? LocalFolderModel,
                           let selectFolderURL = localFolderList.first(where: {$0.isSame(as: localFolder)})?.url {
                            //선택된 폴더가 존재하며, 로컬 폴더 일때
                            //저장된 저장 폴더 세팅 (저장 폴더 URL이 sandbox URL 변경으로 변경되어 있을 수 있으니 주의)
                            selectedFolderRx.accept(LocalFolderModel(url: selectFolderURL))
                        }
                        else {
                            //TODO: 선택된 폴더가 존재하며, 로컬폴더가 아닐때 아무동작 안해야함. (확인)
                        
                        }
                    } else {
                        //선택된 폴더가 없을 때 nil일 때만 디폴츠 폴더.
                        CameraSetting.selectedFolder = DefaultFolderModel()
                        selectedFolderRx.accept(DefaultFolderModel())
                    }
                case .changed:
                    //현재 선택이 로컬 폴더이고, 그 폴더가 존재안하면 Default 폴더로 변경
                    if let selectedFolder = CameraSetting.selectedFolder,
                       let localFolder = selectedFolder as? LocalFolderModel,
                       !localFolderList.contains(where: {$0.isSame(as: localFolder)}) {
                        selectedFolderRx.accept(DefaultFolderModel())
                    }
                    
                    
                case .filesUpdated:
                    break
                }
            }
            .disposed(by: disposeBag)
        
        FolderService.shared.configure(rootURL: DefaultFolderModel().url)
    }
    
    //MARK: - SelectSaveFolderVCDelegate 저장 폴더 변경
    func selectSaveFolderVC(_ vc: SelectSaveFolderVC, didSelectFolder folder: any FolderModelProtocol) {
        selectedFolderRx.accept(folder)
        CameraSetting.selectedFolder = folder
    }
    
    //MARK: - 사진 저장
    enum SavePhotoError: Error {
        case noSelectedFolder
        case failToMakeUniqueName
        case failToSaveAtPath
    }
    
    private func savePhoto(photoData data: Data) -> Result<URL,SavePhotoError> {
        let selected = selectedFolderRx.value
        
        if let localFolder = selected as? LocalFolderModel {
            let destination = localFolder.url
            let fileName = makePhotoFileName(fileTypeString: photoFileFormat.string)
            let newFileURL = destination.appendingPathComponent(fileName)
            guard let uniqueURL = makeUniqueFileURL(url: newFileURL) else { return .failure(.failToMakeUniqueName) }
            return fileManager.createFile(atPath: uniqueURL.path, contents: data) ?  .success(uniqueURL) : .failure(.failToSaveAtPath)
        } else {
            //TODO: 구글 등 다른 폴더
        }
        
    }
    // 🔹 비디오 저장 처리
    private func saveVideo(videoURL: URL) -> Result<URL, SavePhotoError> {
        let selected = selectedFolderRx.value
        
        if let localFolder = selected as? LocalFolderModel {
            let destination = localFolder.url
            let fileName = makePhotoFileName(fileTypeString: "mov")
            let destURL = destination.appendingPathComponent(fileName)
            
            guard let uniqueURL = makeUniqueFileURL(url: destURL) else {
                return .failure(.failToMakeUniqueName)
            }
            
            do {
                try fileManager.copyItem(at: videoURL, to: uniqueURL)
                return .success(uniqueURL)
            } catch {
                return .failure(.failToSaveAtPath)
            }
        }
    }
    
    ///현재시간을 베이스로 파일명을 반환
    private func makePhotoFileName(fileTypeString: String ) -> String {
        let format = "yyyyMMdd_HHmmss_SSS"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        let timeString = dateFormatter.string(from: Date())
        return timeString + "." + fileTypeString
    }
    
    ///이미 같은 이름의 파일이나 폴더가 있는지 검사. 중복일 경우 뒤에 숫자를 덧붙인 url을 반환한다. ex /.././fileName (1).jpg
    private func makeUniqueFileURL(url originURL:URL) -> URL? {
        let fileFullName = NSString(string:originURL.lastPathComponent) //파일이름 + 확장자
        let fileName = fileFullName.deletingPathExtension //파일이름
        let fileFormat = fileFullName.pathExtension //확장자
        let baseURL = originURL.deletingLastPathComponent() // ./
        
        var uniqueURL = originURL
        for i in 1...100 {
            if !fileManager.fileExists(atPath: uniqueURL.path) {
                return uniqueURL
            } else {
                var newName = fileName + " (\(i))"
                if fileFormat != "" {
                    newName += "." + fileFormat // fileName (1).jpg
                }
                uniqueURL = baseURL.appendingPathComponent(newName)
            }
        }
        hcLog("Error \(#function)")
        return nil
    }

    //MARK: - Widget
    ///위젯 호출 정보가 잇는지 확인하여 동작을 수행한다.
    func doWidgetFolderSelectionIfNeeded() -> Bool {
        guard FolderService.shared.isOnceFetched else { return false }
        
        if let widgetOrder = WidgetSettingManager.shared.widgetOrder, widgetOrder == .selectFolder{
            if let selectedFolder = WidgetSettingManager.shared.widgetSelectedFolder {
                
                //위젯에서 폴더 선택하여 진입시에 처리
                if let localFolder = selectedFolder as? LocalFolderModel,
                   let selectedFolder = folderMap[.local]?.first(where: {$0.isSame(as: localFolder)})
                {
                    CameraSetting.selectedFolder = selectedFolder
                    selectedFolderRx.accept(selectedFolder)
                    
                }
            
                WidgetSettingManager.shared.widgetOrder = nil
                WidgetSettingManager.shared.widgetSelectedFolder = nil
                return true
            } else {
                WidgetSettingManager.shared.widgetOrder = nil
                WidgetSettingManager.shared.widgetSelectedFolder = nil
                return false
            }
        } else if let widgetOrder = WidgetSettingManager.shared.widgetOrder, widgetOrder == .camera {

            selectedFolderRx.accept(DefaultFolderModel())
            WidgetSettingManager.shared.widgetOrder = nil
            WidgetSettingManager.shared.widgetSelectedFolder = nil
            return true
        } else {
            //명령없거나, selectFolder 아닌경우 widgetOrder 초기화 하지 않는다.
            return false
        }
    }

}
