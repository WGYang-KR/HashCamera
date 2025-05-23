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
    
    
    private let videoURL: URL
    private var player: AVPlayer?
    private var playerViewController: AVPlayerViewController?
    private var timeControlStatusObserver: NSKeyValueObservation?
    
    var index: Int = 0
    var imageItem: ImageFileModel!
    
    var navController: UINavigationController? {
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
        let player = AVPlayer(url: videoURL)
        self.player = player
        
        let playerVC = AVPlayerViewController()
        playerVC.player = player
        playerVC.showsPlaybackControls = true
        playerVC.entersFullScreenWhenPlaybackBegins = false
        playerVC.exitsFullScreenWhenPlaybackEnds = false
        playerVC.modalPresentationStyle = .overFullScreen
        playerVC.view.frame = view.bounds
        
        addChild(playerVC)
        view.addSubview(playerVC.view)
        playerVC.didMove(toParent: self)
        self.playerViewController = playerVC
        // 🔍 KVO 등록
          observePlayerStatus()
    }
    
    private func observePlayerStatus() {
        timeControlStatusObserver = player?.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] player, _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch player.timeControlStatus {
                case .playing:
                    self.setNavi(hidden: true)
                case .paused:
                    self.setNavi(hidden: false)
                case .waitingToPlayAtSpecifiedRate:
                    break
                @unknown default:
                    break
                }
            }
        }
    }
        
    func setNavi(hidden: Bool) {
        guard let navController else { return }
        navController.setToolbarHidden(hidden, animated: true)
        navController.setNavigationBarHidden(hidden, animated: true)
    }
    
    func zoomOut() {}
    func cancelRotate(){}
    func confirmRotate(){}
    func rotateLeft(){}
    
    deinit {
        player?.pause()
        player = nil
    }
}
