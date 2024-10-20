//
//  SelectSaveFolderVM.swift
//  HashCamera
//
//  Created by Anto-Yang on 10/15/24.
//
import Foundation

class SelectSaveFolderVM {
    
    private let folderService = FolderService()
    let fileManager = FileManager.default
    
    var rootURL: URL? = URL(string: "./", relativeTo: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first)
    var thumbnailSize: CGSize = .zero
    
    var folderList: [[FolderModel]] = [[],[]]
    var folderListUpdated: ((FolderListUpdateData) -> Void)?
    var selectedFolderUpdated: ((URL?) -> Void)?
    
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
    private(set) var selectedFolder: FolderModel? {
        didSet {
            selectedFolderUpdated?(selectedFolder?.url)
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
        self.folderListUpdated = folderListUpdated
        self.initialSelectedFolder = initialSelectedFolder
        
        guard let rootURL else { return }
        folderService.configure(rootURL: rootURL,
                                folderListUpdated: {[weak self] updateData in
            //업데이트 이벤트 핸들러
            guard let self else { return }
            
            //각 상황에 맞게 폴더목록 업데이트
            switch updateData.changeType {
            case .initiate:
                folderList[0] = virtualFolders
                folderList[1] = updateData.newFileList.map({ FolderModel(type: .folder, url: $0)})
            case .add(let newIndex):
                guard newIndex <= folderList[1].count else { return }
                let newItem = FolderModel(type: .folder, url: updateData.newFileList[newIndex])
                folderList[1].insert(newItem, at: newIndex)
                
            case .delete(let deletedIndex):
                guard deletedIndex < folderList[1].count else { return }
                folderList[1].remove(at: deletedIndex)
                
            case .rename(let oldIndex, let newIndex):
                guard oldIndex < folderList[1].count, newIndex <= folderList[1].count else { return }
                //새 이름을 갱신해야하므로 swap 안하고 삭제,삽입.
                folderList[1].remove(at: oldIndex)
                let newItem = FolderModel(type: .folder, url: updateData.newFileList[newIndex])
                folderList[1].insert(newItem, at: newIndex)
            }
            
            //선택된 폴더정보 유지되도록 작업
            updateSelection(updateData: updateData)
            
            //VC에 업데이트 이벤트 전달
            folderListUpdated?(.init(folderUpdateData: updateData, selectedIndexPath: self.selectedIndexPath))
            
        })
    }
    
    //MARK: - Folder and File CRUD
    func createFolder(folderName: String) async -> Result<URL, FolderService.CreationError> {
        await folderService.createFolder(folderName: folderName)
    }
    
    func renameFolder(at indexPath: IndexPath, newName: String) async -> Result<URL, FolderService.RenameError> {
        guard indexPath.section == 1, folderList[indexPath.section][indexPath.row].type == .folder else { return .failure(.isNotRealFolder) }
        return await folderService.renameFolder(at: indexPath.row, newName: newName)
    }
    
    func deleteFolder(at indexPath: IndexPath) async -> Result<Void, FolderService.DeleteError> {
        guard indexPath.section == 1, folderList[indexPath.section][indexPath.row].type == .folder else { return .failure(.isNotRealFolder) }
        return await folderService.deleteFolder(at: indexPath.row)
    }
    
    //MARK: -
    ///folderList는 갱신되었고, selectedIndexPath, selectedFolder는 업데이트 안된 상태일 때 호출된다. 이전 폴더 선택정보를 유지한다.
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
            
        case .add(_):
            //virtual 폴더 선택이었으면 아무 동작 X
            guard let selectedIndexPath, selectedIndexPath.section == 1 else { return }
            //폴더 선택되어 있었으면 선택되었던 폴더 찾아서 selctedIndexPath 갱신
            guard let selectedFolder, selectedFolder.type == .folder else { return }
            guard let newSelectedIndex = folderList[1].firstIndex(where: { $0.url == selectedFolder.url }) else { return }
            self.selectedIndexPath = .init(row: newSelectedIndex, section: 1)
            
        case .delete(_):
            //virtual 폴더 선택이었으면 아무 동작 X
            //폴더 선택되어 있었으면 선택되었던 폴더 찾아서 selctedIndexPath 갱신
            guard let selectedFolder, selectedFolder.type == .folder else { return }
            
            //선택되었던 폴더를 폴더목록에서 찾는다.
            if let index = folderList[1].firstIndex(where: { $0.url == selectedFolder.url }) {
                self.selectedIndexPath = .init(row: index, section: 1)
                self.selectedFolder = folderList[1][index]
            } else {
                //존재 안하면 allPhotos로 지정
                self.selectedIndexPath = .init(row: 0, section: 0)
                self.selectedFolder = folderList[0][0]
            }
            
        case .rename(let oldIndex, let newIndex):
            self.selectedIndexPath = .init(row: newIndex, section: 1)
            let newItemURL = updateData.newFileList[newIndex]
            self.selectedFolder = .init(type: .folder, url: newItemURL)
        }
    }
}
