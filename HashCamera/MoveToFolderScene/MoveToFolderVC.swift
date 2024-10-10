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
        Task {
            let result = await vm.moveFilesToFolder()
            await MainActor.run {
                moveBackVC(animated: true)
            }
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
            
            Task {
                let result = await self.vm.deleteFolder(at: indexPath)
                switch result {
                case .success:
                    completion(true)
                case .failure:
                    completion(false)
                }
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
