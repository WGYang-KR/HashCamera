//
//  BrowserTabBarController.swift
//  HashCamera
//
//  Created by WG-MacHome on 11/26/23.
//

import UIKit

class BrowserTabBarController: UITabBarController {

    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }
    
    
    func initView() {
        
        self.modalPresentationStyle = .fullScreen
        self.view.backgroundColor = .white
        
        let vc0 = UINavigationController(rootViewController: BrowseriCloudVC())
        let vc1 = UINavigationController(rootViewController: BrowserLocalVC())
        let vc2 = UINavigationController(rootViewController: BrowserLibraryVC())
        vc0.tabBarItem = UITabBarItem(title: "iCloud", image: UIImage.tabIconiCloud, selectedImage: nil)
        vc1.tabBarItem = UITabBarItem(title: "iCloud", image: UIImage.tabIconFile, selectedImage: nil)
        vc2.tabBarItem = UITabBarItem(title: "iCloud", image: UIImage.tabIconPhotoLibrary, selectedImage: nil)

        viewControllers = [vc0, vc1, vc2]
        
        tabBar.barTintColor = .systemGray5
    }
    
    
    ///탭바를 숨기지만 높이는 유지한다.
    func hideTabbar(_ isHidden: Bool) {
        tabBar.isHidden = isHidden
    }
    
    ///탭바를 밑으로 숨기면서 자식 VC의 높이를 늘린다.
    func dropTabbar(_ isDropped: Bool) {
        self.tabBar.isHidden = isDropped
        let currentFrame = self.view.frame
        self.view.frame = currentFrame.insetBy(dx: 0, dy: 1)
        self.view.frame = currentFrame
    }

    
}
