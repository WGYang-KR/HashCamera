//
//  FolderListVC.swift
//  HashCamera
//
//  Created by Anto-Yang on 8/22/24.
//

import UIKit

class FolderListVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var vm: FolderListVM = FolderListVM()
    
    var tempSelectedIndexPath: IndexPath?
    var initialSelectedFolder: FolderModel?
    
    func configure(initialSelectedFolder: FolderModel?) {
        self.initialSelectedFolder = initialSelectedFolder
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: "\(FolderListItemCell.self)", bundle: nil), forCellReuseIdentifier: "\(FolderListItemCell.self)")
        tableView.backgroundColor = .sidebarBackground
        
        //네비게이션바
        let rightItems = [UIBarButtonItem(image: SystemUIImage.folderBadgePlus,
                                      style: .plain,
                                      target: self,
                                      action: #selector(addBtnTapped))]

        setNaviBar(localizedString(forKey: "N003_1", value: "Folder List"), leftItems: [], rightItems: rightItems)
        
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
            case .changed(let deletedIndice, let addedIndice):
                tableView.beginUpdates()
                deletedIndice.reversed().forEach { oldIndex in
                    self.tableView.deleteRows(at: [.init(row: oldIndex, section: 1)], with: .automatic)
                }
                addedIndice.reversed().forEach { newIndex in
                    self.tableView.insertRows(at: [.init(row: newIndex, section: 1)], with: .automatic)
                }
                tableView.endUpdates()
                
                if tableView.indexPathForSelectedRow != updateData.selectedIndexPath {
                    tempSelectedIndexPath = updateData.selectedIndexPath
                    
                    //폴더 추가 일때
                    if addedIndice.count == 1, deletedIndice.count == 0 {
                        tableView.selectRow(at: updateData.selectedIndexPath, animated: false, scrollPosition: .none)
                    }
                }
            case .filesUpdated:
                break
            }
        })
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tableView.setEditing(false, animated: true) // Swipe 취소
    }
    
    @objc func addBtnTapped() {
        //수정 진행 시작표시
        vm.isEditingFolder = true
        // 생성 팝업 띄우기
        FolderCRUDAlert().beginCreateAlert(baseVC: self) { [weak self] success in
            if !success { self?.vm.isEditingFolder = false }
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(FolderListItemCell.self)", for: indexPath) as? FolderListItemCell else
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
            AlertHelper.alertConfirm(baseVC: self,
                                     title: localizedString(forKey: "N009_1", value: "Delete Folder"),
                                     message: localizedString(forKey: "N009_2", value: "All files in the folder will be deleted together.")) {
                Task {
                    let result = await self.vm.deleteFolder(at: indexPath)
                    switch result {
                    case .success:
                        AlertHelper.notesInform(message: localizedString(forKey: "N009_3", value: "Folder deleted"),
                                                color: .systemCyan)
                        completion(true)
                    case .failure(let error):
                        AlertHelper.notesInform(message: localizedString(forKey: "N009_4", value: "Failed to delete folder"), color: .systemRed)
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
            
            let originURL = self.vm.folderList[indexPath.section][indexPath.row].url
            FolderCRUDAlert().beginRenameAlert(baseVC: self, originURL: originURL) { success in
                completion(success)
            }
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
                if !(tableView.indexPathForSelectedRow == tempSelectedIndexPath) {
                    tableView.selectRow(at: tempSelectedIndexPath, animated: false, scrollPosition: .none)
                }
            }
        }
        
    }
 
}
