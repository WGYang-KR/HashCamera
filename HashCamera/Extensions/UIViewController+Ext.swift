//
//  UIViewController+Ext.swift
//  HashCamera
//
//  Created by WG-MacHome on 11/29/23.
//

import UIKit

extension UIViewController {
    
    //현재 VC의 바로 전 VC로 이동시킨다. 상황에 맞게 dismiss, popVC를 수행한다.
    func movePrevVC(animated: Bool, completion: (() -> Void)? = nil) {
        if let navigationController = self.navigationController,
            navigationController.viewControllers.first != self {
            navigationController.popViewController(animated: true, completion: completion)
        } else {
            dismiss(animated: animated, completion: completion)
        }
    }
}
