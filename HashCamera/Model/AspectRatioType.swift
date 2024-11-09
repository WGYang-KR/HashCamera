//
//  AspectRatioType.swift
//  HashCamera
//
//  Created by WG-Yang on 11/3/23.
//

import Foundation

//The aspect ratio is the original image’s width divided by its height.
enum AspectRatioType {
    case square
    case standard
    case wide
    
    var cgFloat: CGFloat {
        switch self {
        case .square:
            return 1
        case .standard:
            return 4/3
        case .wide:
            return 16/9
        }
    }
    
    var string: String {
        switch self{
        case .square:
            return "1:1"
        case .standard:
            return "3:4"
        case .wide:
            return "9:16"
        }
    }
    
}

extension AspectRatioType: CaseIterable {
    static var allCases: [AspectRatioType] {
        return [.standard, .wide, .square]
    }
}
