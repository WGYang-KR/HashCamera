//
//  CALayer+Ext.swift
//  HashCamera
//
//  Created by WG-MacHome on 11/12/23.
//

import UIKit

extension CALayer {
    
    @objc var borderUIColor: UIColor {
        set {
            self.borderColor = newValue.cgColor
        }
        
        get {
            return UIColor(cgColor: self.borderColor!)
        }
    }
}
