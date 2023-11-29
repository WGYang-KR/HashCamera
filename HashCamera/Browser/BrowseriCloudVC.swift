//
//  BrowseriCloudVC.swift
//  HashCamera
//
//  Created by WG-MacHome on 11/29/23.
//

import UIKit
import RxSwift
//import RxGesture
class BrowseriCloudVC: UIViewController {

    
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initNavi()
    }
    
    
    func initNavi() {
        let backBtn = UIBarButtonItem.init(image: UIImage(systemName: "chevron.left")?.withTintColor(.black, renderingMode: .alwaysOriginal),
                                           style: .plain,
                                           target: nil,
                                           action: nil)
        
        backBtn.rx.tap.bind { [weak self] _ in
            self?.movePrevVC(animated: true)
        }.disposed(by: disposeBag)
        
        self.navigationItem.leftBarButtonItem = backBtn
    }
    
}
