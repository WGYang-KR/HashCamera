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

    @Published var folders: [FolderModel] = []
    ///현재 보여지고 있는 폴더목록
    @Published var selectedfolders: [FolderModel] = WidgetSetting.folderList {
        didSet {
            //UserDefaults에 저장한다.
            WidgetSetting.folderList = selectedfolders
            
        }
    }
    /// Widget 폴더목록 관리를 시작한다.
    /// 1. 앱에 진입할 때마다 위젯폴더 존재하는 지 확인하여 유저디폴츠/위젯 갱신.
    /// 2. 폴더목록 갱신될 떄마다 유저디폴츠,위젯 갱신.
    func startMonitor() {
        guard let rootURL: URL = URL(string: "./", relativeTo: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first) else { return }
        FolderService.shared.folderListUpdatedRx
            .bind { [weak self] updateData in
                guard let self else { return }
                let newFolderList = updateData.newFileList.map{FolderModel(type: .folder, url: $0)}
                folders = newFolderList
                validateFolderList(newFolderList: newFolderList)
            }
            .disposed(by: disBag)
        
        
        if FolderService.shared.isMonitoring == false {
            //감시 시작
            FolderService.shared.configure(rootURL: rootURL)
        } else if FolderService.shared.isOnceFetched {
            //이미 패치된 폴더목록 사용
            let newFolderList = FolderService.shared.folderList.map{FolderModel(type: .folder, url: $0)}
            folders = newFolderList
            validateFolderList(newFolderList: newFolderList)
            
        }
        
        ///기존 폴더들 존재하는 지 검사
        func validateFolderList(newFolderList: [FolderModel]) {
            selectedfolders = selectedfolders.filter({newFolderList.contains($0)})
        }
    }

}
