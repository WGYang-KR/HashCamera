//
//  CustomNavi.swift
//  HashCamera
//
//  Created by Anto-Yang on 6/19/25.
//
import UIKit

final class CustomNavi: UINavigationController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var shouldAutorotate: Bool {
        return false
    }
}
