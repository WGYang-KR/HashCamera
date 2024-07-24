//
//  Utils.swift
//  HashCamera
//
//  Created by Anto-Yang on 7/24/24.
//

import Foundation


class Utils {
    
    // 특정 요소를 다른 위치로 이동하는 함수
    static func moveItem<T>(array: inout [T], fromIndex: Int, toIndex: Int) {
        let element = array.remove(at: fromIndex)
        array.insert(element, at: toIndex)
    }
    
}
