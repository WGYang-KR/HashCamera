//
//  WidgetSettingVM.swift
//  HashCamera
//
//  Created by Anto-Yang on 11/30/24.
//
import SwiftUI
import Combine

class WidgetSettingVM: ObservableObject {
    
    var cancellables = Set<AnyCancellable>()
    
    @Published var folders: [WidgetFolderSectionType:[FolderModelWrapper]] = [:]
    @Published var selectedItems: [FolderModelWrapper] = []

    ///폴더목록 관찰 시작
    func initVM() {

        WidgetSettingManager.shared.$allFolders.sink { [weak self] list in
            guard let self else { return }
            ///폴더목록 변화생기면 갱신
            folders = list
        }.store(in: &cancellables)
        
        
        WidgetSettingManager.shared.$selectedFolderList.sink { [weak self] list in
            guard let self else { return }
            ///폴더목록 변화생기면 갱신
            selectedItems = list
        }.store(in: &cancellables)
        
    }

    ///선택/해제 로직
    func toggleSelection(for item: FolderModelWrapper) {
        var _seletedItems = selectedItems
        if let index = selectedItems.firstIndex(of: item) {
            // 이미 선택된 아이템은 해제
            _seletedItems.remove(at: index)
        } else if selectedItems.count < 4 {
            // 최대 4개까지만 선택 가능
            _seletedItems.append(item)
        }
        
        WidgetSettingManager.shared.selectedFolderList = _seletedItems
    }
    
}

extension WidgetSettingVM {
    
    func initSampleData() {
        folders[.local] = [.local(.init(url: URL(string: "file:///private/var/mobile/Containers/Data/Application/E04AC083-53C5-4E12-9B3E-336BBDA17069/Documents/Diet%20Logs/")!)),
                           .local(.init(url: URL(string: "file:///private/var/mobile/Containers/Data/Application/E04AC083-53C5-4E12-9B3E-336BBDA17069/Documents/Diet%20Logs/")!)),
                                  .local(.init(url: URL(string: "file:///private/var/mobile/Containers/Data/Application/E04AC083-53C5-4E12-9B3E-336BBDA17069/Documents/Work/")!)),
                           .local(.init(url: URL(string: "file:///private/var/mobile/Containers/Data/Application/E04AC083-53C5-4E12-9B3E-336BBDA17069/Documents/Idea%20Sketches/")!)),
                           .local(.init(url: URL(string: "file:///private/var/mobile/Containers/Data/Application/E04AC083-53C5-4E12-9B3E-336BBDA17069/Documents/Folder01/")!)),
                           .local(.init(url: URL(string: "file:///private/var/mobile/Containers/Data/Application/E04AC083-53C5-4E12-9B3E-336BBDA17069/Documents/Folder02/")!)),
                           .local(.init(url: URL(string: "file:///private/var/mobile/Containers/Data/Application/E04AC083-53C5-4E12-9B3E-336BBDA17069/Documents/Folder03/")!)),
                           .local(.init(url: URL(string: "file:///private/var/mobile/Containers/Data/Application/E04AC083-53C5-4E12-9B3E-336BBDA17069/Documents/Folder04/")!)),
                           .local(.init(url: URL(string: "file:///private/var/mobile/Containers/Data/Application/E04AC083-53C5-4E12-9B3E-336BBDA17069/Documents/Folder05/")!))
        ]
    }
}
