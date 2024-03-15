//
//  HCAlert.swift
//  HashCamera
//
//  Created by Anto-Yang on 3/16/24.
//

import UIKit

class HCAlert {
    
    
    /// 확인, 취소 버튼이 있는 알람을 표시한다.
    /// - Parameters:
    ///  - baseVC: 알림을 띄울 UIViewController
    ///  - animated: 알람띄울 때 애니메이션 여부
    ///  - title: 알람 제목
    ///  - message: 알람 내용
    ///  - action: 확인 클릭시 수행할 클로저
    static func commonYesNo(baseVC: UIViewController, animated: Bool = true,
                            title: String, message: String? = nil, action: (() -> Void )?) {
        
        let vc = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "확인", style: .default) { _ in
            action?()
        }
        let noAction = UIAlertAction(title: "취소", style: .default)
        
        vc.addAction(noAction)
        vc.addAction(yesAction)
        
        baseVC.present(vc, animated: animated)
        
        
    }
}
