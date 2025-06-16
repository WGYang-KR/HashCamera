//
//  OrientationType.swift
//  HashCamera
//
//  Created by Anto-Yang on 6/14/25.
//

enum OrientationType: CaseIterable {
    case portrait        // 세로
    case landscapeRight  // 가로 (홈버튼 오른쪽)
    case upsideDown      // 거꾸로
    case landscapeLeft   // 가로 (홈버튼 왼쪽)

    
    func next() -> OrientationType {
        let all = Self.allCases
        if let currentIndex = all.firstIndex(of: self) {
            let nextIndex = (currentIndex + 1) % all.count
            return all[nextIndex]
        }
        return self
    }
    
    func previous() -> OrientationType {
        let all = Self.allCases
        if let currentIndex = all.firstIndex(of: self) {
            let prevIndex = (currentIndex - 1 + all.count) % all.count
            return all[prevIndex]
        }
        return self
    }
    
}
