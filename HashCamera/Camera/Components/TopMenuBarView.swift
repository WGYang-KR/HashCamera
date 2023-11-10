//
//  TopMenuBarView.swift
//  HashCamera
//
//  Created by WG-MacHome on 11/9/23.
//

import UIKit
import RxSwift
import RxRelay
import AVFoundation

class TopMenuBarView: UIView {
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var moreMenuBtn: UIButton!
    
    @IBOutlet weak var aspectRatioLabel: UILabel!
    @IBOutlet weak var flashModeBtn: UIButton!
    
    @IBOutlet weak var cameraPositionBtn: UIButton!
    
    
    var disposeBag = DisposeBag()

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }
    
    private func initView() {
        let view = Bundle.main.loadNibNamed("\(TopMenuBarView.self)",
                                            owner: self,
                                            options: nil)?
            .first as! UIView
        view.frame = bounds
        addSubview(view)
    }
    
    func configuration(flashMode: Observable<AVCaptureDevice.FlashMode>) {
        flashMode.subscribe(onNext: { [weak self] mode in
            self?.flashModeBtn.setImage(mode.iconImage, for: .normal)
        })
        .disposed(by: disposeBag)
    }
 
}
