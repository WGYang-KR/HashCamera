//
//  BrowserToolBar.swift
//  HashCamera
//
//  Created by WG-MacHome on 12/5/23.
//

import UIKit

class BrowserToolBar: UIToolbar {
    
    let leftItem = UIBarButtonItem(systemItem: .action)
    private lazy var middleItem: UIBarButtonItem = {
        return UIBarButtonItem(customView: middleLabel )
    }()
    let middleLabel = UILabel()
    let rightItem = UIBarButtonItem(systemItem: .trash)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }
    
    func initView() {
        
        backgroundColor = .systemGray6
        middleLabel.textColor = .black
        middleLabel.font = .systemFont(ofSize: 12)
        middleLabel.text = "항목 보기"
        self.items = [leftItem,
                      UIBarButtonItem.flexibleSpace(),
                      middleItem,
                      UIBarButtonItem.flexibleSpace(),
                      rightItem]
    }
}
