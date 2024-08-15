//
//  AuthorizationManager.swift
//  HashCamera
//
//  Created by WG-MacHome on 10/25/23.
//

import UIKit
import AVFoundation
import Photos

class AuthorizationManager {
    
    static let fileManager = FileManager.default
    
    //MARK: - 카메라 권한
    /// 카메라 권한 상태 확인
    static func checkCameraAuth() async -> Bool {
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            // 권한 요청
            hcLog("notDetermined")
            return await AVCaptureDevice.requestAccess(for: .video)
        case .restricted:
            hcLog("restricted")
            return false
        case .authorized:
            return true
        default:
            // 거절했을 경우
            hcLog("declined")
            return false
        }
    }
    
    /// 카메라 권한 설정이동 팝업
    static func presentCameraAuthAlert(baseVC: UIViewController) {
        let alert = UIAlertController(title: "카메라 권한 필요", message: "앱 사용을 위해 설정으로 이동하여 카메라 권한을 허용해주세요.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .default) { action in
          //취소처리...
            alert.dismiss(animated: true)
        })
        alert.addAction(UIAlertAction(title: "설정", style: .default) { action in
          //설정 이동
            Task {
                await AuthorizationManager.openAppSettings()
            }
            
        })
        baseVC.present(alert, animated: true, completion: nil)
    }
    
    //MARK: - 사진 앨범 권한
    ///앨범 쓰기 권한 확인
    static func checkAlbumAddOnlyPermission(completion: @escaping ( (Bool) -> Void )){
        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .notDetermined:
            // 권한 요청
            hcLog("notDetermined")
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                if status == .authorized || status == .limited {
                    completion(true)
                } else {
                    completion(false)
                }
            }
        case .restricted:
            hcLog("restricted")
            completion(false)
        case .authorized:
            completion(true)
        case .limited:
            hcLog("restricted")
            completion(true) //AddOnly이므로 true?
        case .denied:
            completion(false)
        default:
            // 거절했을 경우
            completion(false)
        }
    }

    ///앨범 읽기/쓰기 권한
    static func checkAlbumReadWritePermission(completion: @escaping ( (Bool) -> Void )){
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .notDetermined:
            // 권한 요청
            hcLog("notDetermined")
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                if status == .authorized {
                    completion(true)
                } else {
                    completion(false)
                }
            }
        case .restricted:
            hcLog("restricted")
            completion(false)
        case .authorized:
            completion(true)
        case .limited:
            hcLog("restricted")
            completion(false)
        case .denied:
            completion(false)
        default:
            completion(false)
        }
    }
    
    ///앨범 접근권한 설정 이동 팝업
    static func presentAlbumAuthAlert(baseVC: UIViewController) {
        let alert = UIAlertController(title: "사진 라이브러리 접근 권한 필요", message: "앱 사용을 위해 설정으로 이동하여 사진 라이브러리 접근 권한을 허용해주세요.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .default) { action in
          //취소처리...
            alert.dismiss(animated: true)
        })
        alert.addAction(UIAlertAction(title: "설정", style: .default) { action in
          //설정 이동
            Task {
                await AuthorizationManager.openAppSettings()
            }
            
        })
        baseVC.present(alert, animated: true, completion: nil)
    }
  
    
    //MARK: - iCloud 권한
    static func checkiCloudAuth() -> Bool {
        // Set iCloudDocsURL Here & Do Nil Check
        if let iCloudDocsURL = fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") {
            // Set Logic Here
            hcLog("iCloudDocsURL: \(iCloudDocsURL)")
            return true
        } else {
            // Handling Exception Here When You Developing
            return false
        }
    }
    
    static func presentiCloudAuthAlert(baseVC: UIViewController) {
        let alert = UIAlertController(title: "iCloud 접근 불가", message: "앱을 삭제 후 재설치 해주세요.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { action in
            alert.dismiss(animated: true)
        })

        baseVC.present(alert, animated: true, completion: nil)
    }
    
    //MARK: - 로컬폴더 권한
    static func checkLocalAuth() -> Bool {
        // Set iCloudDocsURL Here & Do Nil Check
        if let iCloudDocsURL = fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") {
            // Set Logic Here
            hcLog("iCloudDocsURL: \(iCloudDocsURL)")
            return true
        } else {
            // Handling Exception Here When You Developing
            return false
        }
    }
    
    static func presentLocalAuthAlert(baseVC: UIViewController) {
        let alert = UIAlertController(title: "로컬 폴더 접근 불가", message: "앱을 삭제 후 재설치 해주세요.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { action in
            alert.dismiss(animated: true)
        })
        
        baseVC.present(alert, animated: true, completion: nil)
    }
    
    //MARK: - 공통
    
    static func openAppSettings() async {
        // Create the URL that deep links to your app's custom settings.
        if let url = await URL(string: UIApplication.openSettingsURLString),
           await UIApplication.shared.canOpenURL(url) {
            // Ask the system to open that URL.
            await MainActor.run {
                UIApplication.shared.open(url)
            }
          
        }
    }
  
}
