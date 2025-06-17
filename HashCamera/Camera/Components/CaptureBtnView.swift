//
//  CaptureBtnView.swift
//  HashCamera
//
//  Created by WG-MacHome on 11/12/23.
//

import UIKit

class CaptureBtnView: UIButton {

    let iconCapturePhoto = UIImage(resource: .iconCapturePhoto)
    let iconStartRecord = UIImage(resource: .iconRecordStart)
    let iconStopRecord = UIImage(resource: .iconRecordStop)
    
    enum iconType {
        case capturePhoto
        case startRecord
        case stopRecord
    }
    
    func setIcon(_ type: iconType) {
        switch type {
        case .capturePhoto:
            setImage(iconCapturePhoto, for: .normal)
        case .startRecord:
            setImage(iconStartRecord, for: .normal)
        case .stopRecord:
            setImage(iconStopRecord, for: .normal)
        }
    }

}
