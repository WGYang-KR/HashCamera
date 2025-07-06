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
            return PhotoFileFormat(rawValue: rawValue) ?? .jpeg
        }
        set{ UserDefaults.standard.set(newValue.rawValue, forKey: Keys.cmeraSettingPhotoFileFormat.rawValue)}
    }
    
    ///사진 저장 폴더
    static var selectedFolder: (any FolderModelProtocol)? {
        get {
            if let data = UserDefaults.standard.data(forKey: Keys.cameraSettingSelectedFolder.rawValue),
               let wrapper = try? JSONDecoder().decode(FolderModelWrapper.self, from: data) {
                return wrapper.base
            }
            return nil
        }
        set {
            let wrapper: FolderModelWrapper?
            if let folder = newValue as? LocalFolderModel {
                wrapper = .local(folder)
            } else if let folder = newValue as? GoogleDriveFolderModel {
                wrapper = .google(folder)
            } else {
                wrapper = nil
            }

            if let encoded = try? JSONEncoder().encode(wrapper) {
                UserDefaults.standard.set(encoded, forKey: Keys.cameraSettingSelectedFolder.rawValue)
            }
        }
    }

}
