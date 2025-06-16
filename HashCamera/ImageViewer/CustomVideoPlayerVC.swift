//
//  CustomVideoPlayerVC.swift
//  HashCamera
//
//  Created by Anto-Yang on 5/24/25.
//

import UIKit
import AVFoundation
import SnapKit

protocol CustomVideoPlayerVCDelegate: AnyObject {
    func customVideoPlayerVCTapped(_ vc: CustomVideoPlayerVC)
}

/// iOS 15 이상 지원용 커스텀 비디오 플레이어
final class CustomVideoPlayerVC: UIViewController {

    // MARK: - Init

    private let videoURL: URL
    
    var delegate: CustomVideoPlayerVCDelegate?
    
    init(videoURL: URL) {
        self.videoURL = videoURL
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let t = timeObserverToken { player?.removeTimeObserver(t) }
        player?.pause()
        playerLayer = nil
        player = nil
    }

    // MARK: - Private UI & Player 속성

    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var timeObserverToken: Any?

    private let playerContainerView = UIView()
    private let playPauseButton     = UIButton(type: .system)
    private let timeSlider          = UISlider()
    private let currentTimeLabel    = UILabel()
    private let durationLabel       = UILabel()

    private let controlStackView = UIStackView()
    
    private var isPlaying = false

    let playImage = UIImage(systemName: "play.fill")
    let pauseImage = UIImage(systemName: "pause.fill")
    
    // MARK: - Public
    func play() {
        player?.play()
        isPlaying = true
        playPauseButton.setImage(pauseImage, for: .normal)
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        playPauseButton.setImage(playImage, for: .normal)
    }
    
    
    func rotate(_ orientation: OrientationType) {
        guard let playerLayer else { return }

        var angle: CGFloat = 0

        switch orientation {
        case .portrait:
            angle = 0
        case .landscapeRight:
            angle = -.pi / 2
        case .upsideDown:
            angle = .pi
        case .landscapeLeft:
            angle = .pi / 2

        }

        // 앵커 포인트 기준 회전
        CATransaction.begin()
        CATransaction.setDisableActions(true) // 애니메이션 제거
        playerLayer.setAffineTransform(CGAffineTransform(rotationAngle: angle))
        CATransaction.commit()
    }
    
    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configurePlayer()
        configureControls()
        view.addTapGestureRecognizer { [weak self] in
            guard let self else { return }
            delegate?.customVideoPlayerVCTapped(self)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerContainerView.frame = view.bounds
        playerLayer?.frame        = playerContainerView.bounds
    }
    
    // MARK: - Setup

    private func configurePlayer() {
        let player          = AVPlayer(url: videoURL)
        self.player         = player

        let layer           = AVPlayerLayer(player: player)
        layer.videoGravity  = .resizeAspect
        self.playerLayer    = layer

        playerContainerView.layer.addSublayer(layer)
        view.addSubview(playerContainerView)

        addPeriodicTimeObserver()
        addDidFinishPlayObserver()
    }

    private func configureControls() {
        // ▶︎ / ❚❚ 버튼
        playPauseButton.setImage(pauseImage, for: .normal)
        playPauseButton.tintColor = .white
        playPauseButton.addTarget(self,
                                  action: #selector(didTapPlayPause),
                                  for: .touchUpInside)

        // 라벨
        [currentTimeLabel, durationLabel].forEach {
            $0.text = "00:00"
            $0.textColor = .white
            $0.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        }

        // 슬라이더
        timeSlider.addTarget(self,
                             action: #selector(sliderValueChanged(_:)),
                             for: .valueChanged)

        // 스택뷰
        let stack = controlStackView
        stack.addArrangedSubview(currentTimeLabel)
        stack.addArrangedSubview(timeSlider)
        stack.addArrangedSubview(durationLabel)
        
        stack.axis = .horizontal
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        [playPauseButton, stack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        // SnapKit 제약 - 하단 중앙에 고정
        stack.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-16)
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
        
        playPauseButton.snp.makeConstraints { make in
            make.bottom.equalTo(stack.snp.top).offset(-12)
            make.leading.equalTo(stack)
        }
    
    }

    // MARK: - Actions

    @objc private func didTapPlayPause() {
        guard let player, let item = player.currentItem else { return }

        let current = CMTimeGetSeconds(player.currentTime())
        let total   = CMTimeGetSeconds(item.duration)

        if isPlaying {
           pause()
        } else {
            // 끝까지 간 상태면 처음부터 재생
            if abs(current - total) < 0.1 {
                player.seek(to: .zero) { [weak self] _ in
                    self?.play()
                }
                return
            }
          play()
        }
    }

    @objc private func sliderValueChanged(_ sender: UISlider) {
        guard
            let duration = player?.currentItem?.duration,
            duration.isNumeric,                       // NaN / indefinite 방지
            CMTimeGetSeconds(duration) > 0
        else { return }

        let totalSeconds = CMTimeGetSeconds(duration)
        let value        = Double(sender.value) * totalSeconds  // 0‥1 → 초
        let seekTime     = CMTime(seconds: value,
                                  preferredTimescale: 600)
        player?.seek(to: seekTime)
    }

    // MARK: - Time Observer

    private func addPeriodicTimeObserver() {
        guard let player else { return }

        // 0.5 초마다 콜백
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)

        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval,
                                                           queue: .main) { [weak self] time in
            guard
                let self,
                let item = player.currentItem,
                item.duration.isNumeric
            else { return }

            let currentSeconds = CMTimeGetSeconds(time)
            let totalSeconds   = CMTimeGetSeconds(item.duration)

            self.currentTimeLabel.text = self.timeString(from: currentSeconds)
            self.durationLabel.text    = self.timeString(from: totalSeconds)
            self.timeSlider.value      = Float(currentSeconds / totalSeconds)
        }
    }

    private func addDidFinishPlayObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying(_:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
    }
    
    @objc private func playerDidFinishPlaying(_ notification: Notification) {
        isPlaying = false
        playPauseButton.setImage(playImage, for: .normal)
    }
    
    // MARK: - Helpers

    private func timeString(from seconds: Float64) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "--:--" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
