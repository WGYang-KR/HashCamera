//
//  BrowserToolBarView.swift
//  HashCamera
//
//  Created by Anto-Yang on 4/1/24.
//

import UIKit
import SnapKit

class BrowserToolBarView: UIView {

    let toolbar = UIToolbar()
    
    //툴바 구성요소
    let shareBtn = UIBarButtonItem(systemItem: .action)
    
    private lazy var middleItem: UIBarButtonItem = {
        return UIBarButtonItem(customView: middleLabel )
    }()
    
    lazy var middleLabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12.0, weight: .regular)
        label.textColor = .black
        label.snp.makeConstraints { make in
            make.width.equalTo(150)
        }
        return  UILabel()
    }()
    
    let trashBtn = UIBarButtonItem(systemItem: .trash)
    
    
    //툴바하단 배경뷰
    let btmBackgroundView = UIView()
    

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
        
        setupStatus(selectionCount: 0)
        
        addSubview(toolbar)
        toolbar.isTranslucent = false
        toolbar.barTintColor = .systemGray6
        toolbar.items = [shareBtn,
                      UIBarButtonItem.flexibleSpace(),
                      middleItem,
                      UIBarButtonItem.flexibleSpace(),
                      trashBtn]

        toolbar.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.top.equalToSuperview()
        }
        
        addSubview(btmBackgroundView)
        btmBackgroundView.backgroundColor = .systemGray6
        btmBackgroundView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.top.equalTo(toolbar.snp.bottom)
            make.height.equalTo(60)
        }
        
        snp.makeConstraints { make in
            make.height.equalTo(50)
        }
    }
    
    func setupStatus(selectionCount: Int) {
        middleLabel.text = "\(selectionCount)개 파일"

        shareBtn.isEnabled = selectionCount > 0
        trashBtn.isEnabled = selectionCount > 0
    }
}
