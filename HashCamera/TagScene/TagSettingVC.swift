//
//  TagSettingVC.swift
//  HashCamera
//
//  Created by Anto-Yang on 7/22/24.
//

import UIKit

class TagSettingVC: UIViewController, UITableViewDataSource, UITableViewDelegate,  UITableViewDragDelegate, UITableViewDropDelegate {
    
    let tagService = TagService.shared
    @IBOutlet weak var tableView: UITableView!
    
    var items: [String] = ["Item 1", "Item 2", "Item 3", "Item 4"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        tableView.dragInteractionEnabled = true
        
        tableView.register(UINib(nibName: "\(TagListItemCell.self)", bundle: nil), forCellReuseIdentifier: "\(TagListItemCell.self)")
        
        let naviAddBarBtnItem = UIBarButtonItem(image: SystemUIImage.plus,
                                                style: .plain,
                                                target: self,
                                                action: #selector(addBtnTapped))
        
        setNaviBar("Edit Tags", leftItems: [naviBackBarButtonItem()], rightItems: [naviAddBarBtnItem])
    }
    
    
    @objc func addBtnTapped() {
        
    }
    
    //MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(TagListItemCell.self)", for: indexPath) as? TagListItemCell else
        {return UITableViewCell()}
        cell.nameLabel.text = items[indexPath.row]
        return cell
    }
    
    //MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        //쓸어서 삭제 기능
        let deleteAction = UIContextualAction(style: .destructive, title: "삭제(Delete)"){ [weak self] action, view, completion in
            self?.items.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            completion(true)
        }
        
        let swipeActionsConfig =  UISwipeActionsConfiguration(actions: [deleteAction])
        swipeActionsConfig.performsFirstActionWithFullSwipe = false
        return swipeActionsConfig
    }
    
 
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // 수정 팝업 띄우기
        let alert = UIAlertController(title: "Edit Item", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = self.items[indexPath.row]
        }
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            if let textField = alert.textFields?.first, let newText = textField.text, !newText.isEmpty {
                self.items[indexPath.row] = newText
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        }
        alert.addAction(saveAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDragDelegate
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let item = items[indexPath.row]
        let itemProvider = NSItemProvider(object: item as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = item
        return [dragItem]
    }

    // MARK: - UITableViewDropDelegate
    
    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSString.self)
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath else { return }

        coordinator.items.forEach { item in
            if let sourceIndexPath = item.sourceIndexPath, let dragItem = item.dragItem.localObject as? String {
                tableView.performBatchUpdates({
                    // 원래 위치에서 아이템을 제거
                    items.remove(at: sourceIndexPath.row)
                    // 새로운 위치에 아이템을 삽입
                    items.insert(dragItem, at: destinationIndexPath.row)

                    tableView.deleteRows(at: [sourceIndexPath], with: .automatic)
                    tableView.insertRows(at: [destinationIndexPath], with: .automatic)
                })
                coordinator.drop(item.dragItem, toRowAt: destinationIndexPath)
            }
        }
    }

}
