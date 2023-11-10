//
//  CamVC.swift
//  HashCamera
//
//  Created by WG-Yang on 10/24/23.
//

import UIKit

class CamVC: UIViewController {

    let topMenuView = UIView()
    let previewGuideView = UIView()
    let menuView = UIView() //선택된 저장소
    let captureBarView = UIView() //촬영 버튼
    let modeBarView = UIView() //사진/비디오 전환
    
    var storageBtnType: StorageBtnType = .normal
    enum StorageBtnType {
        case normal
        case overlay
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        // 바들 높이는 32로 고정. 카메라 버튼은 80으로 고정
        // 3:4 일때, 167을
        //프리뷰 제외하고 최소 167 남음 또는 안남거나 145
        //상단바, 저장소, 촬영, 사진/비디오 제어바
        // 1: 1: 3 : 1
        //상단바:
        //프리뷰 높이: 화면 가로 / 비율
        //저장소 레이블 바
        //촬영/전후면/ 제어바
        //사진/비디오 제어바
    }
    
    func initView() {
        guard let safeAreaSize = safeAreaSize() else { return }
        let standardPreviewHeight = safeAreaSize.width / AspectRatioType.standard.cgFloat
        let widePreviewHeight = safeAreaSize.width / AspectRatioType.wide.cgFloat
        
        // 19.5: 9
    
        var rowHeight = (safeAreaSize.height - standardPreviewHeight) / 2 //제어 메뉴 뷰들의 기준 높이
    
        if rowHeight < 40 { // 너무 높이가 작으면 저장소 선택 버튼을 오버레이로 변경한다.
            storageBtnType = .overlay
//            rowHeight = (safeAreaSize.height - defaultPreviewHeight) / 4
        } else {
            storageBtnType = .normal
        }
        
    }
    
    func safeAreaSize() -> CGSize? {
        guard let window = UIApplication.shared.windows.first else { return nil }
        let safeAreaSize = CGSize( width: window.safeAreaLayoutGuide.layoutFrame.width,
                                    height: window.safeAreaLayoutGuide.layoutFrame.height)
        hcLog("safeAreaSize: \(safeAreaSize)")
        return safeAreaSize
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
