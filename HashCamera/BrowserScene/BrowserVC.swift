//
//  BrowserVC.swift
//  HashCamera
//
//  Created by Anto-Yang on 7/18/24.
//

import UIKit
import SideMenu

class BrowserVC: UIViewController {

    @IBOutlet weak var bottomBarLabel: UILabel!
    
    let menu  = SideMenuNavigationController(rootViewController: SideMenuVC())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSideMenu()
        initNaviBar()
        initToolbar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    func initNaviBar() {
        let naviLeftItems = [naviBackBarButtonItem(),
                             UIBarButtonItem(image: SystemUIImage.listBullet,
                                             style: .plain,
                                             target: self,
                                             action: #selector(naviListBtnTapped))]
        
        let naviRightItems = [UIBarButtonItem(image: SystemUIImage.checkmarkCircle,
                                              style: .plain,
                                              target: self,
                                              action: #selector(naviSelectionBtnTapped))]
        setNaviBar("Browser", leftItems: naviLeftItems, rightItems: naviRightItems)
    }
    
    func initSideMenu() {
//        menu.setNavigationBarHidden(true, animated: false)
        menu.leftSide = true
    }
    
    func initToolbar() {
    
    }
    
    @objc func naviListBtnTapped() {
        present(menu, animated: true)
    }
    
    @objc func naviSelectionBtnTapped() {
        
    }
    
    @IBAction func shareBtnTapped(_ sender: Any) {
        
    }
    
    @IBAction func trashBtnTapped(_ sender: Any) {
        
    }
    
    @IBAction func tagBtnTapped(_ sender: Any) {
        
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
