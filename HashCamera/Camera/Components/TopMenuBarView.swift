//
//  TopMenuBarView.swift
//  HashCamera
//
//  Created by WG-MacHome on 11/9/23.
//

import UIKit
import RxSwift
import RxRelay
import RxCocoa
import RxGesture
import AVFoundation

class TopMenuBarView: UIView {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var moreMenuBtn: UIButton!
    @IBOutlet weak var aspectRatioBtn: UIButton!
    @IBOutlet weak var flashModeBtn: UIButton!
    @IBOutlet weak var cameraPositionBtn: UIButton!
    
    var disposeBag = DisposeBag()
    
    let moreMenuRx = BehaviorRelay<Void>(value: Void())
    let aspectRatioRx = BehaviorRelay<AspectRatioType>(value: .standard)
    let flashModeRx = BehaviorRelay<AVCaptureDevice.FlashMode>(value: .off)
    let cameraPositionRx = BehaviorRelay<AVCaptureDevice.Position>(value:.back)
    
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
        
        bind()
    }
    
    ///버튼 이벤트와 Rx를 연결한다.
    func bind() {
        
        //더보기 버튼
        moreMenuBtn.rx.tap.bind { [weak self] in
            self?.moreMenuRx.accept(Void())
        }.disposed(by: disposeBag)
        
        
        //사진 비율
        aspectRatioRx.subscribe(onNext: { [weak self] aspectRatio in
            self?.aspectRatioBtn.setTitle(aspectRatio.string, for: .normal)
        }).disposed(by: disposeBag)
        
        aspectRatioBtn.rx.tap.bind{ [weak self] _ in
            guard let self else { return }
            let nextAspectRatio = aspectRatioRx.value.next()
            self.aspectRatioRx.accept(nextAspectRatio)
        }.disposed(by: disposeBag)
                  
        
        //플래시 버튼
        flashModeRx.subscribe(onNext: { [weak self] mode in
            self?.flashModeBtn.setImage(mode.iconImage, for: .normal)
        })
        .disposed(by: disposeBag)
        
        flashModeBtn.rx.tap.bind { [weak self] in
            guard let self else { return }
            let nextflashMode = flashModeRx.value.next()
            flashModeRx.accept(nextflashMode)
        }.disposed(by: disposeBag)
        
        //카메라 전환 버튼
        cameraPositionBtn.rx.tap.bind { [weak self] in
            guard let self else { return }
            let nextPosition: AVCaptureDevice.Position = self.cameraPositionRx.value == .back ? .front : .back
            self.cameraPositionRx.accept(nextPosition)
        }.disposed(by: disposeBag)
        
    }
 
}
