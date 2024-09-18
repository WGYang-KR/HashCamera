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
    
    ///높이에 이 값을 곱하면 가로 값이 나온다.
    ///가로에 이 값을 나누면 세로 값이 나온다
    var cgFloat: CGFloat {
        switch self {
        case .square:
            return 1
        case .standard:
            return 0.75
        case .wide:
            return 0.5625
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
