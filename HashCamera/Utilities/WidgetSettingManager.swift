//
//  WidgetSettingManager.swift
//  HashCamera
//
//  Created by Anto-Yang on 11/30/24.
//

import Foundation
import RxSwift
import RxRelay

class WidgetSettingManager: ObservableObject {
    
    var disBag = DisposeBag()
    
    static let shared = WidgetSettingManager()
    private init() {}

    @Published var allFolders: [FolderModel] = []
    
    ///현재 보여지고 있는 폴더목록
    @Published var selectedFolderList: [FolderModel] = WidgetSetting.folderList {
        didSet {
            //UserDefaults에 저장한다.
            WidgetSetting.folderList = selectedFolderList
            
        }
    }
    
    enum WidgetOrderType {
        case selectFolder
        case camera
        case setting
        case addFolder
    }
    ///위젯에서 수신된 명령
    var widgetOrder: WidgetOrderType?
    var widgetSelectedFolder: FolderModel?
    
    /// Widget 폴더목록 관리를 시작한다.
    /// 1. 앱에 진입할 때마다 위젯폴더 존재하는 지 확인하여 유저디폴츠/위젯 갱신.
    /// 2. 폴더목록 갱신될 떄마다 유저디폴츠,위젯 갱신.
    func startMonitor() {
        guard let rootURL: URL = URL(string: "./", relativeTo: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first) else { return }
        FolderService.shared.folderListUpdatedRx
            .bind { [weak self] updateData in
                guard let self else { return }
                let newFolderList = updateData.newFileList.map{FolderModel(type: .folder, url: $0)}
                allFolders = newFolderList
                validateFolderList(newFolderList: newFolderList)
            }
            .disposed(by: disBag)
        
        
        if FolderService.shared.isMonitoring == false {
            //감시 시작
            FolderService.shared.configure(rootURL: rootURL)
        } else if FolderService.shared.isOnceFetched {
            //이미 패치된 폴더목록 사용
            let newFolderList = FolderService.shared.folderList.map{FolderModel(type: .folder, url: $0)}
            allFolders = newFolderList
            validateFolderList(newFolderList: newFolderList)
            
        }
        
        ///기존 폴더들 존재하는 지 검사
        func validateFolderList(newFolderList: [FolderModel]) {
            ///UUID 변경되었을 수 있으므로 전체 URL에서 필터한다.
            var _selectedFolderList = [FolderModel]()
            selectedFolderList.forEach { item in
                if let _item = newFolderList.first(where: {$0 == item}) {
                    _selectedFolderList.append(_item)
                }
            }
            selectedFolderList = _selectedFolderList
        }
    }
    

}
