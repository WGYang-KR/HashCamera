//
//  AuthorizationManager.swift
//  HashCamera
//
//  Created by WG-MacHome on 10/25/23.
//

import UIKit
import AVFoundation

class AuthorizationManager {
    
    let fileManager = FileManager.default
    
    //MARK: - 카메라 권한
    static func checkCameraAuth() async -> Bool {
        // 카메라 권한 상태 확인
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            // 권한 요청
            return await AVCaptureDevice.requestAccess(for: .video)
        case .restricted:
            return false
        case .authorized:
            return true
        default:
            // 거절했을 경우
            print("Permession declined")
            return false
        }
    }
    
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
    
    //MARK: - 접근 권한
    func getAvailableiCloud() -> Bool {
        // Set iCloudDocsURL Here & Do Nil Check
        if let iCloudDocsURL = fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") {
            // Set Logic Here
            print("iCloudDocsURL: \(iCloudDocsURL)")
            return true
        } else {
            // Handling Exception Here When You Developing
            print("TEST BACK UP :: iCLOUD URL IS NIL CHECK XCODE SETTING")
            return false
        }
    }
    
    //MARK: -
    
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
