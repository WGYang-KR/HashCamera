//
//  SelectSaveFolderVC.swift
//  HashCamera
//
//  Created by Anto-Yang on 10/15/24.
//

import UIKit
protocol SelectSaveFolderVCDelegate: AnyObject {
    func selectSaveFolderVC(_ vc: SelectSaveFolderVC, didSelectFolder folder: FolderModel)
}

class SelectSaveFolderVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    private var vm: SelectSaveFolderVM = SelectSaveFolderVM()
    private var tempSelectedIndexPath: IndexPath?
    
    weak var delegate: SelectSaveFolderVCDelegate?
    var initialSelectedFolder: FolderModel?
    
    func configure(delegate: SelectSaveFolderVCDelegate?, initialSelectedFolder: FolderModel?) {
        self.delegate = delegate
        self.initialSelectedFolder = initialSelectedFolder
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: "\(MoveToFolderListItemCell.self)", bundle: nil), forCellReuseIdentifier: "\(MoveToFolderListItemCell.self)")
        
        //네비게이션바
        let leftItems = [UIBarButtonItem(title: "취소",
                                         style: .plain,
                                         target: self,
                                         action: #selector(cancelBtnTapped))]
        let rightItems = [UIBarButtonItem(image: SystemUIImage.folderBadgePlus,
                                          style: .plain,
                                          target: self,
                                          action: #selector(addBtnTapped))]
        
        setNaviBar("저장 폴더 선택", leftItems: leftItems, rightItems: rightItems)
        
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
                    
                    if !tableView.isEditing {
                        if tableView.indexPathForSelectedRow != tempSelectedIndexPath {
                            tableView.selectRow(at: tempSelectedIndexPath, animated: false, scrollPosition: .none)
                            if let selectedFolder = vm.selectedFolder {
                                delegate?.selectSaveFolderVC(self, didSelectFolder: selectedFolder)
                            }
                        }
                    }
                    
                }
            case .filesUpdated:
                break
            }
        })
        
    }
    
    
    @objc func cancelBtnTapped() {
        moveBackVC(animated: true)
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(MoveToFolderListItemCell.self)", for: indexPath) as? MoveToFolderListItemCell else
        {return UITableViewCell()}
        
        let item  = vm.folderList[indexPath.section][indexPath.row]
        cell.nameLabel.text = item.name
        return cell
    }
    
    //MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        hcLog("셀 선택: \(indexPath), delegate: \(String(describing: delegate))")
        vm.selectedIndexPath = indexPath
        if let selectedFolder = vm.selectedFolder {
            delegate?.selectSaveFolderVC(self, didSelectFolder: selectedFolder)
        }
        moveBackVC(animated: true)
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
                    
                    if let selectedFolder = vm.selectedFolder {
                        delegate?.selectSaveFolderVC(self, didSelectFolder: selectedFolder)
                    }
                }
            }
        }
        
    }
}
