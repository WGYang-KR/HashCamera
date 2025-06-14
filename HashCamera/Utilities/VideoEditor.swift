//
//  VideoEditor.swift
//  HashCamera
//
//  Created by Anto-Yang on 6/14/25.
//

import Foundation
import AVFoundation

class VideoEditor {

    func rotateVideo(url: URL, orientation: OrientationType) {
        rotateVideoUsingReaderWriter(inputURL: url, orientation: orientation) { tempURL in
            guard let tempURL = tempURL else {
                hcLog("❌ 회전 실패")
                return
            }

            do {
                // 기존 파일 삭제 후 temp 파일을 이동
                try FileManager.default.removeItem(at: url)
                try FileManager.default.moveItem(at: tempURL, to: url)
                hcLog("✅ 회전된 영상이 원본에 덮어쓰기 되었습니다: \(url)")
            } catch {
                hcLog("❌ 파일 덮어쓰기 실패: \(error.localizedDescription)")
            }
        }
    }
    
    private func rotateVideoUsingReaderWriter(
        inputURL: URL,
        orientation: OrientationType,
        completion: @escaping (URL?) -> Void
    ) {
        hcLog("목표 orientation: \(orientation)")
        
        let asset = AVAsset(url: inputURL)

           guard let videoTrack = asset.tracks(withMediaType: .video).first else {
               hcLog("❌ 비디오 트랙 없음")
               completion(nil)
               return
           }

           let transform = orientationTransform(for: orientation, size: videoTrack.naturalSize)

           let composition = AVMutableComposition()
           guard let videoCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
               hcLog("❌ 트랙 복사 실패")
               completion(nil)
               return
           }

           do {
               try videoCompositionTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration),
                                                         of: videoTrack,
                                                         at: .zero)
           } catch {
               hcLog("❌ 트랙 복사 에러: \(error)")
               completion(nil)
               return
           }

        let originalTransform = videoTrack.preferredTransform
        let additionalTransform = orientationTransform(for: orientation, size: videoTrack.naturalSize)
        // 순서 중요! 기존 transform을 먼저 곱하고 그 뒤에 내가 원하는 방향을 적용
        let finalTransform = originalTransform.concatenating(additionalTransform)
        hcLog("orginTrans:\(originalTransform)\naddTrans:\(additionalTransform)\nfinalTrans:\(finalTransform)")
        videoCompositionTrack.preferredTransform = finalTransform

           // 오디오 트랙도 복사 (선택)
           if let audioTrack = asset.tracks(withMediaType: .audio).first,
              let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
               try? audioCompositionTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: audioTrack, at: .zero)
           }

           let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
           try? FileManager.default.removeItem(at: outputURL)

           guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough) else {
               hcLog("❌ export 세션 생성 실패")
               completion(nil)
               return
           }

           exportSession.outputURL = outputURL
           exportSession.outputFileType = .mov
           exportSession.shouldOptimizeForNetworkUse = true

           exportSession.exportAsynchronously {
               DispatchQueue.main.async {
                   if exportSession.status == .completed {
                       hcLog("✅ 무인코딩 회전 완료: \(outputURL)")
                       completion(outputURL)
                   } else {
                       hcLog("❌ 무인코딩 export 실패: \(exportSession.error?.localizedDescription ?? "알 수 없음")")
                       completion(nil)
                   }
               }
           }
    }
    
    private func orientationTransform(for orientation: OrientationType, size: CGSize) -> CGAffineTransform {
        switch orientation {
        case .portrait:
            return .identity
        case .landscapeRight:
            return CGAffineTransform(rotationAngle: -.pi / 2).translatedBy(x: -size.height, y: 0)
        case .upsideDown:
            return CGAffineTransform(rotationAngle: .pi).translatedBy(x: -size.width, y: -size.height)
        case .landscapeLeft:
            return CGAffineTransform(rotationAngle: .pi / 2).translatedBy(x: 0, y: -size.width)
        }
    }

    private func orientationRenderSize(for orientation: OrientationType, size: CGSize) -> CGSize {
        switch orientation {
        case .portrait, .upsideDown:
            return size
        case .landscapeLeft, .landscapeRight:
            return CGSize(width: size.height, height: size.width)
        }
    }
    
}
