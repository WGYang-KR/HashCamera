//
//  StorageModel.swift
//  HashCamera
//
//  Created by WG-MacHome on 11/13/23.
//

import UIKit
import RxSwift
import RxRelay

class StorageModel {
    
    let selectedStorgeType: BehaviorRelay<StorageType>
    
    init(selectedStorgeType: StorageType) {
        self.selectedStorgeType = BehaviorRelay<StorageType>(value: selectedStorgeType)
    }
    
}
