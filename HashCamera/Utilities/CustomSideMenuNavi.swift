//
//  CustomSideMenuNavi.swift
//  HashCamera
//
//  Created by Anto-Yang on 6/19/25.
//

import SideMenu

final class CustomSideMenuNavi: SideMenuNavigationController {
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
}
