//
//  NibUIView.swift
//  GMoneyTrans
//
//  Created by WG-Yang on 8/2/24.
//  Copyright © 2024 GmoneyTrans. All rights reserved.
//

import UIKit

///이 클래스를 상속받으면 같은 이름의 Nib(.xib) 파일을 자동으로 로드하함
class NibUIView: UIView {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadXib()
        self.initView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadXib()
        self.initView()
    }
    
    private func loadXib() {
        let identifier = String(describing: type(of: self))
        let nibs = Bundle.main.loadNibNamed(identifier, owner: self, options: nil)
        
        guard let customView = nibs?.first as? UIView else { return }
        customView.frame = self.bounds
        self.addSubview(customView)
        
        self.backgroundColor = .clear
    }
    
    func initView() { }
}
