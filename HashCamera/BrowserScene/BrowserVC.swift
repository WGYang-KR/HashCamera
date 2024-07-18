//
//  BrowserVC.swift
//  HashCamera
//
//  Created by Anto-Yang on 7/18/24.
//

import UIKit
import SideMenu

class BrowserVC: UIViewController {

    let menu  = SideMenuNavigationController(rootViewController: SideMenuVC())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        menu.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    @IBAction func sideMenuTapped(_ sender: Any) {
        
        present(menu, animated: true)
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
