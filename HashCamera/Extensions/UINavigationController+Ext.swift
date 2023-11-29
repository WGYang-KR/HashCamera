//
//  UINavigationController+Ext.swift
//  HashCamera
//
//  Created by WG-MacHome on 11/29/23.
//

import UIKit

extension UINavigationController {
    
    func popViewController(animated:Bool, completion: (() -> Void)?) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        self.popViewController(animated: animated)
        CATransaction.commit()
    }
    
    func pushViewController(_ viewController: UIViewController, animated:Bool, completion: (() -> Void)?) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        self.pushViewController(viewController, animated: animated)
        CATransaction.commit()
    }
}
