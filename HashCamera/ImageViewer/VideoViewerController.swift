//
//  VideoViewerController.swift
//  HashCamera
//
//  Created by Anto-Yang on 5/23/25.
//

import UIKit
import AVKit

/// 동영상을 전체 화면으로 보여주는 뷰 컨트롤러
class VideoViewerController: UIViewController, MediaViewerControllerProtocol {
    
    var index: Int = 0
    var imageItem: ImageFileModel!
    
    private let videoURL: URL
    private var player: AVPlayer? {
        get {
            playerViewController?.player
        }
        set {
            playerViewController?.player = newValue
        }
    }
    private var playerViewController: CustomVideoPlayerViewController?
    private var currentAngle: CGFloat = 0

    private var navController: UINavigationController? {
        return (parent as? ImageCarouselViewController)?.navigationController
        
    }
    
    init(index: Int, imageItem: ImageFileModel) {
        self.index = index
        self.imageItem = imageItem
        self.videoURL = imageItem.url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPlayer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player?.play()
    }
    
    private func setupPlayer() {
//        let player = AVPlayer(url: videoURL)
//        self.player = player
//        
        let playerVC = CustomVideoPlayerViewController(videoURL: videoURL)
        
//        let playerVC = AVPlayerViewController()
//        playerVC.player = player
//        playerVC.showsPlaybackControls = true
//        playerVC.entersFullScreenWhenPlaybackBegins = false
//        playerVC.exitsFullScreenWhenPlaybackEnds = false
//        playerVC.modalPresentationStyle = .overFullScreen
//        playerVC.view.frame = view.bounds
        
        addChild(playerVC)
        view.addSubview(playerVC.view)
        playerVC.didMove(toParent: self)
        self.playerViewController = playerVC

    }
    
        
    private func setNavi(hidden: Bool) {
        guard let navController else { return }
        navController.setToolbarHidden(hidden, animated: true)
        navController.setNavigationBarHidden(hidden, animated: true)
    }
    
    func zoomOut() {}
    func cancelRotate(){}
    func confirmRotate(){}
    @objc func rotateLeft() {
        currentAngle -= 90
        if currentAngle <= -360 { currentAngle = 0 }
        applyRotation(angle: currentAngle)
    }

    private func applyRotation(angle: CGFloat) {
        guard let playerVC = playerViewController else { return }

        let radians = angle * .pi / 180
        playerVC.view.transform = CGAffineTransform(rotationAngle: radians)

        // 회전 후 프레임 재조정
        playerVC.view.frame = view.bounds
    }
    
    deinit {
        player?.pause()
        player = nil
    }
}
