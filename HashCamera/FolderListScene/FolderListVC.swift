//
//  FolderListVC.swift
//  HashCamera
//
//  Created by Anto-Yang on 8/22/24.
//

import UIKit
import RxSwift
import RxRelay

protocol FolderListVMProtocol: AnyObject {
    var selectedFolderIndexPath: BehaviorRelay<IndexPath> { get }
    var folders: BehaviorRelay<[[FolderListItemModel]]> { get }
    func createFolder(folderName: String ) async -> Result<URL, FolderService.CreationError>
    func renameFolder(at index: IndexPath, newName: String) async -> Result<URL,FolderService.RenameError>
    func deleteFolder(at index: IndexPath) async -> Result<Void, FolderService.DeleteError>
}

class FolderListVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var disposeBag = DisposeBag()
    @IBOutlet weak var tableView: UITableView!
    
    var vm: FolderListVMProtocol!
    
    var sceneType: ScenetType = .sideMenu
    
    enum ScenetType {
        case sideMenu
        case moveFolder
    }
    
    ///moveFolder에 사용될 떄는 확인 버튼이 눌리면 이 값을 selectedFolderIndexPath에 넣는다.
    var tempSelectedIndexPath: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: "\(FolderListItemCell.self)", bundle: nil), forCellReuseIdentifier: "\(FolderListItemCell.self)")
        
        //네비게이션바
        var leftItems: [UIBarButtonItem] = []
        switch sceneType {
        case .sideMenu:
            leftItems = []
        case .moveFolder:
            leftItems = [naviBackBarButtonItem()]
        }
        let naviAddBarBtnItem = UIBarButtonItem(image: SystemUIImage.plus,
                                                style: .plain,
                                                target: self,
                                                action: #selector(addBtnTapped))
        
        setNaviBar("폴더 관리", leftItems: leftItems, rightItems: [naviAddBarBtnItem])
        
        
        //폴더 vm 연결
        vm.folders.withUnretained(self).subscribe { owner, event in
            owner.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        vm.selectedFolderIndexPath.subscribe { [weak self] indexPath in
            Task { @MainActor in
                self?.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
            }
        }.disposed(by: disposeBag)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
        return vm.folders.value.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return vm.folders.value[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(FolderListItemCell.self)", for: indexPath) as? FolderListItemCell else
        {return UITableViewCell()}
        
        let item  = vm.folders.value[indexPath.section][indexPath.row]
        cell.nameLabel.text = item.name
        return cell
    }
    
    //MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch sceneType {
        case .sideMenu:
            vm.selectedFolderIndexPath.accept(indexPath)
        case .moveFolder:
            tempSelectedIndexPath = indexPath
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        guard vm.folders.value[indexPath.section][indexPath.row].type == .folder else { return nil}
        //쓸어서 삭제 기능
        let deleteAction = UIContextualAction(style: .destructive, title: nil){ [weak self] action, view, completion in
            guard let self else { return }
            Task {
                let result = await self.vm.deleteFolder(at: indexPath)
                switch result {
                case .success(let success):
                    completion(true)
                case .failure(let failure):
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
                textField.text = self.vm.folders.value[indexPath.section][indexPath.row].name
            }
            let saveAction = UIAlertAction(title: "확인", style: .default) { _ in
                if let textField = alert.textFields?.first, let newText = textField.text,
                   !newText.isEmpty {
                    Task {
                        let result = await self.vm.renameFolder(at: indexPath, newName: newText)
                        switch result {
                        case .success(let success):
                            completion(true)
                        case .failure(let failure):
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

    @objc func cancelBtnTapped() {
        tableView.selectRow(at: vm.selectedFolderIndexPath.value, animated: true, scrollPosition: .top)
        moveBackVC(animated: true)
    }
    
    @objc func confirmBtnTapped() {
        guard let tempSelectedIndexPath else { return }
        vm.selectedFolderIndexPath.accept(tempSelectedIndexPath)
    }
}
