//
//  FolderListVC.swift
//  HashCamera
//
//  Created by Anto-Yang on 8/22/24.
//

import UIKit
import RxSwift

class FolderListVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var disposeBag = DisposeBag()
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: "\(TagListItemCell.self)", bundle: nil), forCellReuseIdentifier: "\(TagListItemCell.self)")
        
        let naviAddBarBtnItem = UIBarButtonItem(image: SystemUIImage.plus,
                                                style: .plain,
                                                target: self,
                                                action: #selector(addBtnTapped))
        
        setNaviBar("폴더 관리", leftItems: [naviBackBarButtonItem()], rightItems: [naviAddBarBtnItem])
        
        FolderService.shared.folders.withUnretained(self).subscribe { owner, event in
            owner.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        FolderService.shared.prepare()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        FolderService.shared.fetchFolders()
    }
    
    @objc func addBtnTapped() {
        // 수정 팝업 띄우기
        let alert = UIAlertController(title: "폴더 추가", message: "추가하실 폴더 이름을 입력해 주세요.", preferredStyle: .alert)
        alert.addTextField()
        let saveAction = UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            if let textField = alert.textFields?.first, let newText = textField.text, !newText.isEmpty {
                guard let self else { return }
                Task {
                    let result = await FolderService.shared.createFolder(folderName: newText)
                }
            }
        }
        alert.addAction(saveAction)
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    //MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return FolderService.shared.folders.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(TagListItemCell.self)", for: indexPath) as? TagListItemCell else
        {return UITableViewCell()}
        let item = FolderService.shared.folders.value[indexPath.row]
        cell.nameLabel.text =  item.lastPathComponent
//        cell.countLabel.text = "(" + String(describing: item.filePaths.count)  + ")"
        return cell
    }
    
    //MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        //쓸어서 삭제 기능
        let deleteAction = UIContextualAction(style: .destructive, title: "삭제"){ [weak self] action, view, completion in
            guard let self else { return }
            Task {
                let result = await FolderService.shared.deleteFolder(at: indexPath.row)
                switch result {
                case .success(let success):
                    completion(true)
                case .failure(let failure):
                    completion(false)
                }
            }
        }
        
        let renameAction = UIContextualAction(style: .normal, title: "이름 변경"){ [weak self] action, view, completion in
            guard let self else { return }
            // 수정 팝업 띄우기
            let alert = UIAlertController(title: "이름변경", message: "변경할 이름 입력하세요.", preferredStyle: .alert)
            alert.addTextField { textField in
                textField.text = FolderService.shared.folders.value[indexPath.row].lastPathComponent
            }
            let saveAction = UIAlertAction(title: "확인", style: .default) { _ in
                if let textField = alert.textFields?.first, let newText = textField.text,
                   !newText.isEmpty {
                    Task {
                        let result = await FolderService.shared.renameFolder(at: indexPath.row, newName: newText)
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
        
        
        let swipeActionsConfig =  UISwipeActionsConfiguration(actions: [deleteAction,renameAction])
        swipeActionsConfig.performsFirstActionWithFullSwipe = false
        return swipeActionsConfig
    }

}
