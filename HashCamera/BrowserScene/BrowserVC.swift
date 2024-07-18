//
//  BrowserVC.swift
//  HashCamera
//
//  Created by Anto-Yang on 7/18/24.
//

import UIKit
import SideMenu

class BrowserVC: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var selectionBtn: UIButton!
    @IBOutlet weak var bottomBarLabel: UILabel!
    
    let menu  = SideMenuNavigationController(rootViewController: SideMenuVC())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSideMenu()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    
    func initSideMenu() {
        menu.setNavigationBarHidden(true, animated: false)
        menu.leftSide = true
    }
    
    
    @IBAction func sideMenuBtnTapped(_ sender: Any) {
        present(menu, animated: true)
    }
    
    @IBAction func selectionBtnTapped(_ sender: Any) {
        
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
