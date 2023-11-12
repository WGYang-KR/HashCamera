//
//  CamVC.swift
//  HashCamera
//
//  Created by WG-Yang on 10/24/23.
//

import UIKit

class CamVC: UIViewController {

    
    @IBOutlet weak var topMenuView: TopMenuBarView!
 
    @IBOutlet weak var preview916GuideView: UIView!
    @IBOutlet weak var preview34GuideView:UIView!
    
    @IBOutlet weak var bottomMenuContainer: UIView!
    @IBOutlet weak var StorageButton: UIButton!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var BrowseButton: UIButton!
   
    var cameraModel: CameraModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cameraModel = CameraModel(position: .back,
                                  flashMode: .off, aspectRatio: .standard, fileType: .jpeg)
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
