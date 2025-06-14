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
    private var playerVC: CustomVideoPlayerVC?
    private var curOrientation: OrientationType = .portrait

    private var navController: UINavigationController? {
        return (parent as? ImageCarouselViewController)?.navigationController
        
    }
    
    //MARK: - Life Cycle
    
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
        playerVC?.pause()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playerVC?.play()
    }
    
    private func setupPlayer() {
        let playerVC = CustomVideoPlayerVC(videoURL: videoURL)
        playerVC.delegate = self
        
        addChild(playerVC)
        view.addSubview(playerVC.view)
        playerVC.didMove(toParent: self)
        self.playerVC = playerVC

    }
    
    private func naviToggle(animated: Bool = true) {
        guard let navController else { return }
        navController.setToolbarHidden(!navController.isToolbarHidden, animated: animated)
        navController.setNavigationBarHidden(!navController.isNavigationBarHidden, animated: animated)
    }
    
    func zoomOut() {}
    func cancelRotate(){
        let nextOrient: OrientationType = .portrait
        playerVC?.rotate(nextOrient)
        curOrientation = nextOrient
    }
    
    func confirmRotate(){
        if curOrientation != .portrait {
            let editor = VideoEditor()
            editor.rotateVideo(url: videoURL, orientation: curOrientation)
        }
        
    }
    
    @objc func rotateLeft() {
        let nextOrient = curOrientation.next()
        playerVC?.rotate(nextOrient)
        curOrientation = nextOrient
    }
    
    deinit {
        playerVC?.pause()
        playerVC = nil
    }
}

extension VideoViewerController: CustomVideoPlayerVCDelegate {
    func customVideoPlayerVCTapped(_ vc: CustomVideoPlayerVC) {
        naviToggle()
    }
    
}
