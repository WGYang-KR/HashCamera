//
//  CaseIterable+Ext.swift
//  HashCamera
//
//  Created by WG-MacHome on 11/10/23.
//

import Foundation

extension CaseIterable where Self: Equatable {
//    func previous() -> Self {
//        let all = Self.allCases
//        let idx = all.firstIndex(of: self)!
//        let previous = all.index  all.index(before: idx)
//        return all[previous < all.startIndex ? all.index(before: all.endIndex) : previous]
//    }
    
    func next() -> Self {
        let all = Self.allCases
        let idx = all.firstIndex(of: self)!
        let next = all.index(after: idx)
        return all[next == all.endIndex ? all.startIndex : next]
    }
}
