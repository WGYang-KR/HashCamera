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

    var disBag = DisposeBag()
    
    let cameraModel: CameraModel = CameraModel(position: .back,
                                               flashMode: .off,
                                               aspectRatio: .standard)

    let fileManager = FileManager.default

    ///폴더 감시, 조회 서비스
    var folderList: [FolderModel] = []
    ///선택된 저장 폴더
    let selectedFolderRx = BehaviorRelay<FolderModel>(value: defaultFolder)
    ///사진 저장 포맷
    var photoFileFormat: PhotoFileFormat {
        return CameraSetting.photoFileFormat
    }
    
    ///촬영시 true -> 저장 완료 후 false
    let isCapturingPhoto = BehaviorRelay(value: false)
    let errorOccuredRx = PublishRelay<Error>()
    var disposeBag = DisposeBag()
    
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
            
            isCapturingPhoto.accept(false) //촬영저장 끝
            
        }.disposed(by: disposeBag)
    }
    
    func capturePhoto() {
        isCapturingPhoto.accept(true) //촬영 저장 시작
        cameraModel.capturePhoto() //촬영 후 결과값은 capturedPhotoData로 수신
    }
    
    //MARK: - 저장폴더
    static var defaultFolder: FolderModel {
        FolderModel(type: .defaultFolder, url: Utils.documentsFolderURL)
    }
    
    func initFolderSelection() {

        FolderService.shared.folderListUpdatedRx
            .bind { [weak self] updateData in
                //업데이트 이벤트 핸들러
                guard let self else { return }
                folderList = updateData.newFileList.map{FolderModel(type: .folder, url: $0)}
                switch updateData.changeType {
                    case .initiate:
                    //저장된 저장 폴더 세팅 (저장 폴더 URL이 sandbox URL 변경으로 변경되어 있을 수 있으니 주의)
                    if let savedSelectedFolder = CameraSetting.selectedFolder,
                       savedSelectedFolder.type == .folder,
                       let savedFolderURL = folderList.first(where: {$0.url.lastPathComponent == savedSelectedFolder.url.lastPathComponent})?.url {
                            selectedFolderRx.accept(.init(type: .folder, url: savedFolderURL))
                        
                    } else {
                        //디폴츠 폴더.
                        CameraSetting.selectedFolder = Self.defaultFolder
                        selectedFolderRx.accept(Self.defaultFolder)
                    }
                case .changed:
                    //현재 선택 폴더가 존재안하면 Default폴더로 변경
                    if selectedFolderRx.value.type == .folder,
                       !folderList.contains(where: { $0.url == self.selectedFolderRx.value.url}) {
                           selectedFolderRx.accept(Self.defaultFolder)
                    }
                case .filesUpdated:
                    break
                }
            }
            .disposed(by: disposeBag)
        FolderService.shared.configure(rootURL: Self.defaultFolder.url)
    }
    
    //MARK: - SelectSaveFolderVCDelegate 저장 폴더 변경
    func selectSaveFolderVC(_ vc: SelectSaveFolderVC, didSelectFolder folder: FolderModel) {
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
        let destination = selectedFolderRx.value.url
        
        let fileName = makePhotoFileName(fileTypeString: photoFileFormat.string)
        let newFileURL = destination.appendingPathComponent(fileName)
        guard let uniqueURL = makeUniqueFileURL(url: newFileURL) else { return .failure(.failToMakeUniqueName) }
        return fileManager.createFile(atPath: uniqueURL.path, contents: data) ?  .success(uniqueURL) : .failure(.failToSaveAtPath)

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

}
