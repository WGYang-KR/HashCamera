//
//  PhotoFileFormat.swift
//  HashCamera
//
//

import Foundation
import AVFoundation
//추후에 순서 수정 금지. 유저디폴츠에 Int형으로 저장됨.
@objc enum PhotoFileFormat: Int, CaseIterable, Identifiable {
    case heic
    case jpeg
    
    var id: Self { self }
    
    var string: String {
        switch self {
        case .heic:
            return "heic"
        case .jpeg:
            return "jpeg"
        }
    }
    
    var avVideoCodecType: AVVideoCodecType {
        switch self {
        case .heic:
            return .hevc
        case .jpeg:
            return .jpeg
        }
    }
}
