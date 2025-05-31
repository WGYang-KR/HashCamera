//
//  CustomVideoPlayerViewController.swift
//  HashCamera
//
//  Created by Anto-Yang on 5/24/25.
//

import UIKit
import AVFoundation
//
//  CustomVideoPlayerViewController.swift
//  Created by ChatGPT on 2025-05-24
//

import UIKit
import AVFoundation

/// iOS 15 이상 지원용 커스텀 비디오 플레이어
final class CustomVideoPlayerViewController: UIViewController {

    // MARK: - Init

    private let videoURL: URL

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
    }

    // MARK: - Private UI & Player 속성

    var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var timeObserverToken: Any?

    private let playerContainerView = UIView()
    private let playPauseButton     = UIButton(type: .system)
    private let timeSlider          = UISlider()
    private let currentTimeLabel    = UILabel()
    private let durationLabel       = UILabel()

    private var isPlaying = false

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configurePlayer()
        configureControls()
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
    }

    private func configureControls() {
        // ▶︎ / ❚❚ 버튼
        playPauseButton.setTitle("▶︎", for: .normal)
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
        let stack = UIStackView(arrangedSubviews: [currentTimeLabel,
                                                   timeSlider,
                                                   durationLabel])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        [playPauseButton, stack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            playPauseButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                                    constant: -60),
            playPauseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                          constant: -20)
        ])
    }

    // MARK: - Actions

    @objc private func didTapPlayPause() {
        guard let player else { return }

        if isPlaying {
            player.pause()
            playPauseButton.setTitle("▶︎", for: .normal)
        } else {
            player.play()
            playPauseButton.setTitle("❚❚", for: .normal)
        }
        isPlaying.toggle()
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

    // MARK: - Helpers

    private func timeString(from seconds: Float64) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "--:--" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
