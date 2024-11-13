//
//  SelectableFolderListVM.swift
//  HashCamera
//
//  Created by Anto-Yang on 10/31/24.
//

import Foundation
import RxSwift
import RxRelay

class SelectableFolderListVM {
    var disBag = DisposeBag()
    
    var rootURL: URL? = URL(string: "./", relativeTo: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first)
    var thumbnailSize: CGSize = .zero
    
    var folderList: [[FolderModel]] = [[],[]]
    var folderListUpdated: ((FolderListUpdateData) -> Void)?
    var selectedFolderUpdated: ((FolderModel?) -> Void)?
    
    ///초기 선택된 폴더
    private var initialSelectedFolder: FolderModel?
    
    ///선택된 폴더 인덱스 정보
    var selectedIndexPath: IndexPath? {
        didSet {
            if let selectedIndexPath {
                self.selectedFolder = self.folderList[selectedIndexPath.section][selectedIndexPath.row]
            } else {
                self.selectedFolder = nil
            }
            hcLog("VM selectedIndexPath: \(String(describing: selectedIndexPath))로 변경됨. selectedFolder: \(selectedFolder?.name ?? "nil")")
        }
    }
    ///선택된 폴더 정보
    var selectedFolder: FolderModel? {
        didSet {
            selectedFolderUpdated?(selectedFolder)
        }
    }

    lazy var virtualFolders: [FolderModel] = {
        guard let rootURL else { return [] }
        return [.init(type: .defaultFolder, url: rootURL)]
    }()
                    
    struct FolderListUpdateData {
        let folderUpdateData: FolderMonitor.FolderUpdateData
        let selectedIndexPath: IndexPath?
    }
    
    func configure(initialSelectedFolder: FolderModel?, folderListUpdated: ((FolderListUpdateData) -> Void)?) {
        guard let rootURL else { return }
        self.initialSelectedFolder = initialSelectedFolder
        self.folderListUpdated = folderListUpdated
        
        FolderService.shared.folderListUpdatedRx
            .bind { [weak self] updateData in
                //업데이트 이벤트 핸들러
                guard let self else { return }
                
                //각 상황에 맞게 폴더목록 업데이트
                switch updateData.changeType {
                case .initiate:
                    initFolderList(updateData.newFileList.map({ FolderModel(type: .folder, url: $0)}))
                case .changed(let deletedIndice, let addedIndice):
                    //삭제된 폴더 뒤에서 부터 제거
                    deletedIndice.reversed().forEach { deletedIndex in
                        self.folderList[1].remove(at: deletedIndex)
                    }
                    
                    //추가된 폴더 뒤에서 부터 추가
                    addedIndice.reversed().forEach { addedIndex in
                        let newItem = FolderModel(type: .folder, url: updateData.newFileList[addedIndex])
                        self.folderList[1].insert(newItem, at: addedIndex)
                    }
                case .filesUpdated:
                    return
                    
                }
                //선택된 폴더정보 유지되도록 작업
                updateSelection(updateData: updateData)
                
                //VC에 업데이트 이벤트 전달
                folderListUpdated?(.init(folderUpdateData: updateData, selectedIndexPath: self.selectedIndexPath))
                
            }
            .disposed(by: disBag)
        
        if FolderService.shared.isMonitoring == false {
            FolderService.shared.configure(rootURL: rootURL)
        } else {
            ///임의로 지금 initiate 된것 처럼 UpdateData를 만들어서 이벤트를 발생시킨다.
            let fakeUpdateData = FolderMonitor.FolderUpdateData(newFileList: FolderService.shared.folderList,
                                                            changeType: .initiate)
            
            initFolderList(fakeUpdateData.newFileList.map({ FolderModel(type: .folder, url: $0)}))
            
            //선택된 폴더정보 유지되도록 작업
            updateSelection(updateData: fakeUpdateData)
            
            //VC에 업데이트 이벤트 전달
            folderListUpdated?(.init(folderUpdateData: fakeUpdateData, selectedIndexPath: self.selectedIndexPath))
        }
        
        ///폴더 목록을 초기화 한다.
        func initFolderList(_ realFolderList: [FolderModel]) {
            folderList[0] = virtualFolders
            folderList[1] = realFolderList
        }
    }
    
    //MARK: FolderListVMProtocol
    func createFolder(folderName: String) async -> Result<URL, FolderService.CreationError> {
        await FolderService.shared.createFolder(folderName: folderName)
    }
    
    func renameFolder(at indexPath: IndexPath, newName: String) async -> Result<URL, FolderService.RenameError> {
        guard indexPath.section == 1, folderList[indexPath.section][indexPath.row].type == .folder else { return .failure(.isNotRealFolder) }
        return await FolderService.shared.renameFolder(at: indexPath.row, newName: newName)
    }
    
    func deleteFolder(at indexPath: IndexPath) async -> Result<Void, FolderService.DeleteError> {
        guard indexPath.section == 1, folderList[indexPath.section][indexPath.row].type == .folder else { return .failure(.isNotRealFolder) }
        return await FolderService.shared.deleteFolder(at: indexPath.row)
    }
    

    ///folderList는 갱신되었고, selectedIndexPAth, selectedFolder는 업데이트 안된 상태일 때 호출된다. 이전 폴더 선택정보를 유지한다.
    private func updateSelection(updateData: FolderMonitor.FolderUpdateData) {
        
        switch updateData.changeType {
        case .initiate:
            guard folderList[0].count > 0 else { return }
            
            if let initialSelectedFolder,
               let index = folderList[1].firstIndex(where: { $0.url == initialSelectedFolder.url }) {
                //초기 폴더 선택값 세팅
                selectedIndexPath = .init(row: index, section: 1)
                selectedFolder = folderList[1][index]
            }
            else {
                //All Photos 선택
                
                selectedIndexPath = .init(row: 0, section: 0)
                selectedFolder = folderList[0][0]
            }
        case .changed(let deletedIndice, let addedIndice):
            
            if addedIndice.count == 1, (deletedIndice.count == 0 || deletedIndice.count == 1), let newFolderIndex = addedIndice[safe: 0] {
                //추가된 폴더가 딱 1개이면서, 삭제 폴더가 0개(폴더 추가) 또는 1개(이름변경)이면 선택폴더로 지정.
                let newSelectedFolder = folderList[1][newFolderIndex]
                if let index = folderList[1].firstIndex(where: { $0.url == newSelectedFolder.url }) {
                    //추가된 폴더 인덱스 찾아서 선택
                    self.selectedIndexPath = .init(row: index, section: 1)
                    self.selectedFolder = folderList[1][index]
                    
                } else {
                    //못 찾으면 기본 폴더로 설정
                    self.selectedIndexPath = .init(row: 0, section: 0)
                    self.selectedFolder = folderList[0][0]
                }
                
            } else if let selectedFolder, selectedFolder.type == .defaultFolder {
                //기본 폴더 선택이었으면 아무 동작 X
                return
            } else if let selectedFolder, selectedFolder.type == .folder {
                
                //선택되었던 폴더를 폴더목록에서 찾는다.
                if let index = folderList[1].firstIndex(where: { $0.url == selectedFolder.url }) {
                    self.selectedIndexPath = .init(row: index, section: 1)
                    self.selectedFolder = folderList[1][index]
                } else {
                    //못 찾으면 기본 폴더로 설정
                    self.selectedIndexPath = .init(row: 0, section: 0)
                    self.selectedFolder = folderList[0][0]
                }
                
            }
        case .filesUpdated:
            break
        }
        
    }
    
}
