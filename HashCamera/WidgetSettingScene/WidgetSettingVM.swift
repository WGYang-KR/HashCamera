//
//  WidgetSettingVM.swift
//  HashCamera
//
//  Created by Anto-Yang on 11/30/24.
//
import SwiftUI
import RxSwift

class WidgetSettingVM: ObservableObject {
    var disBag = DisposeBag()
    
    @Published var folders: [FolderModel] = []
    @Published var selectedItems: [FolderModel] = []

    var rootURL: URL? = URL(string: "./", relativeTo: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first)
    

    ///폴더목록 관찰 시작
    func initVM() {
        guard let rootURL else { return }
        selectedItems = WidgetSetting.folderList
        
        FolderService.shared.folderListUpdatedRx
            .bind {  [weak self] updateData in
                //업데이트 이벤트 핸들러
                guard let self else { return }
                folders = updateData.newFileList.map({ FolderModel(type: .folder, url: $0)})
                validateSeletedFolders()
                
            }
            .disposed(by: disBag)
        
        ///폴더목록 가져오기
        if FolderService.shared.isMonitoring == false {
            FolderService.shared.configure(rootURL: rootURL)
        } else {
            folders = FolderService.shared.folderList.map({ FolderModel(type: .folder, url: $0)})
            validateSeletedFolders()
        }
        
        //사라진 폴더는 목록에서 삭제
        func validateSeletedFolders() {
            selectedItems = selectedItems.filter{ self.folders.contains($0)}
        }
        
    }
    

    
    ///선택/해제 로직
    func toggleSelection(for item: FolderModel) {
        if let index = selectedItems.firstIndex(of: item) {
            // 이미 선택된 아이템은 해제
            selectedItems.remove(at: index)
        } else if selectedItems.count < 4 {
            // 최대 4개까지만 선택 가능
            selectedItems.append(item)
        }
        
        WidgetSetting.folderList = selectedItems
    }
    
}

extension WidgetSettingVM {
    
    func initSampleData() {
        folders = [.init(type: .folder,
                         url: URL(string: "file:///private/var/mobile/Containers/Data/Application/E04AC083-53C5-4E12-9B3E-336BBDA17069/Documents/Diet%20Logs/")!),
                   .init(type: .folder,
                         url: URL(string: "file:///private/var/mobile/Containers/Data/Application/E04AC083-53C5-4E12-9B3E-336BBDA17069/Documents/Work/")!),
                   .init(type: .folder,
                         url: URL(string: "file:///private/var/mobile/Containers/Data/Application/E04AC083-53C5-4E12-9B3E-336BBDA17069/Documents/Idea%20Sketches/")!),
                   .init(type: .folder,
                         url: URL(string: "file:///private/var/mobile/Containers/Data/Application/E04AC083-53C5-4E12-9B3E-336BBDA17069/Documents/Receipts/")!),
                   .init(type: .folder,
                         url: URL(string: "file:///private/var/mobile/Containers/Data/Application/E04AC083-53C5-4E12-9B3E-336BBDA17069/Documents/Folder01/")!),
                   .init(type: .folder,
                         url: URL(string: "file:///private/var/mobile/Containers/Data/Application/E04AC083-53C5-4E12-9B3E-336BBDA17069/Documents/Folder02/")!),
                   .init(type: .folder,
                         url: URL(string: "file:///private/var/mobile/Containers/Data/Application/E04AC083-53C5-4E12-9B3E-336BBDA17069/Documents/Folder03/")!),
                   .init(type: .folder,
                         url: URL(string: "file:///private/var/mobile/Containers/Data/Application/E04AC083-53C5-4E12-9B3E-336BBDA17069/Documents/Folder04/")!),
                    .init(type: .folder,
                          url: URL(string: "file:///private/var/mobile/Containers/Data/Application/E04AC083-53C5-4E12-9B3E-336BBDA17069/Documents/Folder05/")!)
        ]
    }
}
