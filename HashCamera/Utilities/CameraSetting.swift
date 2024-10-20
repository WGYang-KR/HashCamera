//
//  CameraSetting.swift
//  HashCamera
//
//  Created by Anto-Yang on 3/28/24.
//

import Foundation
import AVFoundation

class CameraSetting {
    
    enum Keys: String {
        case cameraSettingLocationInfo
        case cameraSettingPosition
        case cmeraSettingPhotoFileFormat
        case cameraSettingSelectedFolder
    }
    
    ///위치 저장 여부
    static var locationInfo: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.cameraSettingLocationInfo.rawValue)}
        set { UserDefaults.standard.setValue(newValue, forKey: Keys.cameraSettingLocationInfo.rawValue)}
    }
    
    ///카메라 전/후면 최근 상태
    static var lastPosition: AVCaptureDevice.Position {
        get {
            let intValue = UserDefaults.standard.integer(forKey: Keys.cameraSettingPosition.rawValue)
            return AVCaptureDevice.Position(rawValue: intValue) ?? .back //기본값
        }
        set { UserDefaults.standard.setValue(newValue.rawValue, forKey: Keys.cameraSettingPosition.rawValue)}
    }
    
    ///사진 저장 포맷
    static var photoFileFormat: PhotoFileFormat {
        get {
            let rawValue =  UserDefaults.standard.integer(forKey: Keys.cmeraSettingPhotoFileFormat.rawValue)
            return PhotoFileFormat(rawValue: rawValue) ?? .heif
        }
        set{ UserDefaults.standard.set(newValue.rawValue, forKey: Keys.cmeraSettingPhotoFileFormat.rawValue)}
    }
    
    ///사진 저장 폴더
    static var selectedFolder: FolderModel? {
        get {
            if let savedData = UserDefaults.standard.data(forKey: Keys.cameraSettingSelectedFolder.rawValue) {
                return try? JSONDecoder().decode(FolderModel.self, from: savedData)
            } else {
                return nil
            }
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: Keys.cameraSettingSelectedFolder.rawValue)
            }
        }
    }

}
