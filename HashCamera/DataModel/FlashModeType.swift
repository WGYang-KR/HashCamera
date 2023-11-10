//
//  FlashModeType.swift
//  HashCamera
//
//  Created by WG-MacHome on 11/7/23.
//

import UIKit
import AVFoundation

extension AVCaptureDevice.FlashMode {
    
    var iconImage: UIImage {
        switch self {
        case .off:
            return UIImage(systemName: "bolt.slash")!
        case .on:
            return UIImage(systemName: "bolt.fill")!
        case .auto:
            return UIImage(systemName: "bolt.badge.a.fill")!
        @unknown default:
            return UIImage(systemName: "bolt.trianglebadge.exclamationmark.fill")!
        }
    }
    
}

extension AVCaptureDevice.FlashMode: CaseIterable {
    public static var allCases: [AVCaptureDevice.FlashMode] {
        return [.off, .on, .auto]
    }
}
