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

class CamVM {
    let cameraModel: CameraModel = CameraModel(position: .back,
                                               flashMode: .off,
                                               aspectRatio: .standard)
    let fileManager = FileManager.default

    ///선택된 저장 폴더
    var seletedFolder: FolderListItemModel?
    ///사진 저장 포맷
    var photoFileFormat: PhotoFileFormat = .jpeg
    
    ///촬영시 true -> 저장 완료 후 false
    let isCapturingPhoto = BehaviorRelay(value: false)
    var disposeBag = DisposeBag()
    
    init() {
        initVM()
    }

    func initVM() {
        
        ///사진 캡처결과 받아서 저장소에 저장하기 연결
        cameraModel.capturedPhotoData.bind { [weak self] photoData in
            let _ = self?.savePhoto(photoData: photoData)
            self?.isCapturingPhoto.accept(false) //촬영저장 끝
        }.disposed(by: disposeBag)
    }
    
    //MARK: - 사진 촬영
    func capturePhoto() {
        isCapturingPhoto.accept(true) //촬영 저장 시작
        cameraModel.capturePhoto() //촬영 후 결과값은 capturedPhotoData로 수신
    }
    
    
    //MARK: - 사진 저장
    enum SavePhotoError: Error {
        case noSelectedFolder
        case failToMakeUniqueName
        case failToSaveAtPath
    }
    
    private func savePhoto(photoData data: Data) -> Result<URL,SavePhotoError> {
        guard let destination = seletedFolder?.url else { return .failure(.noSelectedFolder)}
        
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
