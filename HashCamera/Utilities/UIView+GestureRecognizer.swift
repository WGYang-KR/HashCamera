//
//  UIView+GestureRecognizer.swift
//  GMoneyTrans
//
//  Created by WG-Yang on 7/16/24.
//  Copyright © 2024 GmoneyTrans. All rights reserved.
//

import UIKit

extension UIView: @retroactive UIGestureRecognizerDelegate {
    typealias TapGestureHandler = (() -> Void)?
    typealias TouchDownGestureHandler = ((Bool) -> Void)?
    
    private struct GestureAssociatedKey {
        fileprivate static var tapGestureKey = "associated_tapGestureKey"
        fileprivate static var touchDownGestureKey = "associated_touchDownGestureKey"
    }
    
    private var tapGestureRecognizerHandler: TapGestureHandler? {
        get {
            withUnsafePointer(to: &GestureAssociatedKey.tapGestureKey) { key in
                return objc_getAssociatedObject(
                    self,
                    key
                ) as? TapGestureHandler
            }
        }
        set {
            if let newValue = newValue {
                withUnsafePointer(to: &GestureAssociatedKey.tapGestureKey) { key in
                    objc_setAssociatedObject(
                        self,
                        key,
                        newValue,
                        objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
                    )
                }
            }
        }
    }
    
    private var touchDownGestureRecognizerHandler: TouchDownGestureHandler? {
        get {
            withUnsafePointer(to: &GestureAssociatedKey.touchDownGestureKey) { key in
                return objc_getAssociatedObject(
                    self,
                    key
                ) as? TouchDownGestureHandler
            }
        }
        set {
            if let newValue = newValue {
                withUnsafePointer(to: &GestureAssociatedKey.touchDownGestureKey) { key in
                    objc_setAssociatedObject(
                        self,
                        key,
                        newValue,
                        objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
                    )
                }
            }
        }
    }
    
    
    public func addTapGestureRecognizer(_ handler: (() -> Void)?) {
        self.isUserInteractionEnabled = true
        self.tapGestureRecognizerHandler = handler
        let tapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(handleTapGesture)
        )
        tapGestureRecognizer.delegate = self
        self.addGestureRecognizer(tapGestureRecognizer)
    }

    public func addTouchDownGestureRecognizer(_ handler: ((Bool) -> Void)?) {
        self.isUserInteractionEnabled = true
        self.touchDownGestureRecognizerHandler = handler
        let touchDownGestureRecognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleTouchDownGesture)
        )
        touchDownGestureRecognizer.delegate = self
        touchDownGestureRecognizer.minimumPressDuration = 0 //터치 다운을 즉시 인식
        self.addGestureRecognizer(touchDownGestureRecognizer)
        
    }
        
    @objc private func handleTapGesture(sender: UITapGestureRecognizer) {
        if let action = self.tapGestureRecognizerHandler {
            action?()
        }
    }
    
    @objc private func handleTouchDownGesture(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if let action = self.touchDownGestureRecognizerHandler {
            if gestureRecognizer.state == .began {
                action?(true)
            } else if gestureRecognizer.state == .ended || gestureRecognizer.state == .cancelled {
                action?(false)
            }
        }
    }
  
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

