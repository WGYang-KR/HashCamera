//
//  MoveToFolderVC.swift
//  HashCamera
//
//  Created by Anto-Yang on 9/23/24.
//

import UIKit

class MoveToFolderVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    private var vm: MoveToFolderVM = MoveToFolderVM()
    private var tempSelectedIndexPath: IndexPath?
    
    var initialSelectedFolder: URL?
    
    func configure(initialSelectedFolder: URL?, targetFileList: [ImageFileModel]) {
        self.initialSelectedFolder = initialSelectedFolder
        self.vm.targetFileList = targetFileList
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: "\(MoveToFolderListItemCell.self)", bundle: nil), forCellReuseIdentifier: "\(MoveToFolderListItemCell.self)")
        tableView.backgroundColor = .sidebarBackground
        
        //네비게이션바
        let leftItems = [UIBarButtonItem(title: "취소",
                                         style: .plain,
                                         target: self,
                                         action: #selector(cancelBtnTapped))]
        let rightItems = [UIBarButtonItem(title: "이동",
                                          style: .plain,
                                          target: self,
                                          action: #selector(moveBtnTapped)),
                          UIBarButtonItem(image: SystemUIImage.folderBadgePlus,
                                          style: .plain,
                                          target: self,
                                          action: #selector(addBtnTapped))]
        
        setNaviBar("이동할 폴더 선택", leftItems: leftItems, rightItems: rightItems)
        
        vm.configure(initialSelectedFolder: initialSelectedFolder, folderListUpdated: { [weak self] updateData in
            
            guard let self else { return }
            switch updateData.folderUpdateData.changeType {
            case .initiate:
                tableView.reloadData { [weak self] in
                    guard let self else { return }
                    if tableView.indexPathForSelectedRow != updateData.selectedIndexPath {
                        tableView.selectRow(at: updateData.selectedIndexPath, animated: true, scrollPosition: .top)
                    }
                }
            case .add(let newIndex):
                tableView.beginUpdates()
                tableView.insertRows(at: [.init(row: newIndex, section: 1)], with: .automatic)
                tableView.endUpdates()
                
                if tableView.indexPathForSelectedRow != updateData.selectedIndexPath {
                    tempSelectedIndexPath = updateData.selectedIndexPath
                }
                
            case .rename(let oldIndex, let newIndex):
                tableView.beginUpdates()
                tableView.deleteRows(at: [.init(row: oldIndex, section: 1)], with: .automatic)
                tableView.insertRows(at: [.init(row: newIndex, section: 1)], with: .automatic)
                tableView.endUpdates()
                
                if tableView.indexPathForSelectedRow != updateData.selectedIndexPath {
                    tempSelectedIndexPath = updateData.selectedIndexPath
                }
                
            case .delete(let deletedIndex):
                tableView.beginUpdates()
                tableView.deleteRows(at: [.init(row: deletedIndex, section: 1)], with: .automatic)
                tableView.endUpdates()
                
                if tableView.indexPathForSelectedRow != updateData.selectedIndexPath {
                    tempSelectedIndexPath = updateData.selectedIndexPath
                }
                
            }
        })
        
    }
    
    @objc func moveBtnTapped() {
        // 1. 중복 파일을 미리 체크
        guard let duplicates = try? vm.checkDuplicateFiles() else {
            //MARK: 기본 확인알람
            return
        }
        
        // 2. 중복 파일이 있을 경우 알림창 띄우기
        if !duplicates.isEmpty {
            hcLog("Duplicate files found: \(duplicates)")
            // 중복 파일이 있을 때 사용자에게 덮어쓰기, 이름 변경, 취소 옵션 제공
            showDuplicateFilesAlert(duplicates)
        } else {
            hcLog("No duplicates found. Moving files directly.")
            // 중복이 없으면 바로 파일 이동
            self.moveFilesOperation(overrite: false)
        }
    }
    
    @objc func cancelBtnTapped() {
        moveBackVC(animated: true)
    }
    
    @objc func addBtnTapped() {
        // 수정 팝업 띄우기
        let alert = UIAlertController(title: "폴더 추가", message: "추가하실 폴더 이름을 입력해 주세요.", preferredStyle: .alert)
        alert.addTextField()
        let saveAction = UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            guard let self else { return }
            if let textField = alert.textFields?.first, let newText = textField.text, !newText.isEmpty {
                Task {
                    let result = await self.vm.createFolder(folderName: newText)
                }
            }
        }
        alert.addAction(saveAction)
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    //MARK: - 중복파일 처리 팝업
    
    /// 중복 파일 확인 후 알림창을 띄우는 함수
    func showDuplicateFilesAlert(_ duplicates: [String]) {
        // 알림창 생성
        let alert = UIAlertController(title: "Duplicate Files Found", message: "There are \(duplicates.count) duplicate files. How would you like to proceed?", preferredStyle: .alert)
        
        // 덮어쓰기 옵션
        alert.addAction(UIAlertAction(title: "Overwrite All", style: .destructive, handler: { _ in
            print("User chose to overwrite all duplicate files.")
            // 덮어쓰기 옵션으로 파일 이동 실행
            self.moveFilesOperation(overrite: true)
        }))
        
        // 이름 변경 옵션
        alert.addAction(UIAlertAction(title: "Rename All", style: .default, handler: { _ in
            print("User chose to rename all duplicate files.")
            // 이름 변경 옵션으로 파일 이동 실행
            self.moveFilesOperation(overrite: false)
        }))
        
        // 취소 옵션
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            print("User cancelled the operation.")
            // 취소 시 아무것도 하지 않음
        }))
        
        // 알림창 띄우기
        present(alert, animated: true, completion: nil)
    }
    
    func moveFilesOperation(overrite: Bool) {
        Task {
            let results = try? await self.vm.moveFiles(overwrite: true)
            await MainActor.run {
                if let results {
                    self.handleFileMoveResults(results)
                } else {
                    //TODO: 선택된 폴더 오류 팝업
                    
                }
                
            }
        }
    }
    
    // 파일 이동 결과를 처리하는 함수
    func handleFileMoveResults(_ results: [Result<URL, MoveToFolderVM.FileMoveError>]) {
        var errorMessage = ""
        
        for result in results {
            switch result {
            case .success(let fileURL):
                hcLog("Successfully moved: \(fileURL.lastPathComponent)")
            case .failure(let error):
                switch error {
                case .unknown:
                    hcLog("Failed to move")
                case .fileOverwriteFailed(let file, let error):
                    let message = "Failed to overwrite: \(file.lastPathComponent)."
                    hcLog(message + " " + "Error: \(error)")
                    errorMessage += message + "\n"
                    
                case .fileRenameFailed(let file, let error):
                    let message = "Failed to move: \(file.lastPathComponent)."
                    hcLog(message + " " + "Error: \(error)")
                    errorMessage += message + "\n"
                    
                case .fileMoveFailed(let file, let error):
                    let message = "Failed to move: \(file.lastPathComponent)/"
                    hcLog(message + " " + "Error: \(error)")
                    errorMessage += message + "\n"
                }
            }
        }
        
        if !errorMessage.isEmpty {
            //TODO: 알림 팝업 띄우기
        } else {
            //성공
            moveBackVC(animated: true)
        }
    }
    
    //MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return vm.folderList.count >= 2 ? vm.folderList.count : 0
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return vm.folderList[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(MoveToFolderListItemCell.self)", for: indexPath) as? MoveToFolderListItemCell else
        {return UITableViewCell()}
        
        let item  = vm.folderList[indexPath.section][indexPath.row]
        cell.nameLabel.text = item.name
        return cell
    }
    
    //MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        hcLog("셀 선택: \(indexPath)")
        vm.selectedIndexPath = indexPath
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        hcLog("셀 선택해제: \(indexPath)")
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        guard indexPath.section == 1, vm.folderList[indexPath.section][indexPath.row].type == .folder else { return nil}
        
        //선택된 셀 복원을 위해 indexPath 임시저장
        if let curIndexPath = tableView.indexPathForSelectedRow { //연속 스와이프 할 수 있으므로
            tempSelectedIndexPath = curIndexPath
        }
    
        //쓸어서 삭제 기능
        let deleteAction = UIContextualAction(style: .destructive, title: nil){ [weak self] action, view, completion in
            guard let self else { return }
            
            AlertHelper.alertConfirm(baseVC: self, title: "폴더를 삭제하시겠습니까?", message: "") {
                Task {
                    let result = await self.vm.deleteFolder(at: indexPath)
                    switch result {
                    case .success:
                        AlertHelper.notesInform(message: "폴더 삭제 완료됨", color: .systemCyan)
                        completion(true)
                    case .failure(let error):
                        AlertHelper.notesInform(message: "폴더 삭제 실패", color: .systemRed)
                        completion(false)
                    }
                }
            } cancelCompletion: {
                completion(false)
            }
        }
        deleteAction.image = SystemUIImage.trash
        
        let renameAction = UIContextualAction(style: .normal, title: nil){ [weak self] action, view, completion in
            guard let self else { return }
            
            // 수정 팝업 띄우기
            let alert = UIAlertController(title: "이름변경", message: "변경할 이름 입력하세요.", preferredStyle: .alert)
            alert.addTextField { textField in
                textField.text = self.vm.folderList[indexPath.section][indexPath.row].name
            }
            let saveAction = UIAlertAction(title: "확인", style: .default) { _ in
                if let textField = alert.textFields?.first, let newText = textField.text,
                   !newText.isEmpty {
                    Task {
                        let result = await self.vm.renameFolder(at: indexPath, newName: newText)
                        switch result {
                        case .success:
                            completion(true)
                        case .failure:
                            completion(false)
                        }
                    }
                }
            }
            alert.addAction(saveAction)
            let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
            alert.addAction(cancelAction)
            
            present(alert, animated: true, completion: nil)
        }
        
        renameAction.image = SystemUIImage.pencil
        
        
        let swipeActionsConfig =  UISwipeActionsConfiguration(actions: [deleteAction,renameAction])
        swipeActionsConfig.performsFirstActionWithFullSwipe = false
        return swipeActionsConfig
    }

    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        
        hcLog("스와이프 종료")
        if let tempSelectedIndexPath,
           tableView.numberOfSections > tempSelectedIndexPath.section {
            
            hcLog("tableView.numberOfRows:\(tableView.numberOfRows), tempSelectedIndexPath: \(tempSelectedIndexPath)")
            if tableView.numberOfRows(inSection:  tempSelectedIndexPath.section) > tempSelectedIndexPath.row {
                hcLog("선택된 셀 복원: \(tempSelectedIndexPath)")
                if tableView.indexPathForSelectedRow != tempSelectedIndexPath {
                    tableView.selectRow(at: tempSelectedIndexPath, animated: false, scrollPosition: .none)
                }
            }
        }
        
    }
}
