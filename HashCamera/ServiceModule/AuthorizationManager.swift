//
//  AuthorizationManager.swift
//  HashCamera
//
//  Created by WG-MacHome on 10/25/23.
//

import Foundation


class AuthorizationManager {
    
    let fileManager = FileManager.default
    
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
}
