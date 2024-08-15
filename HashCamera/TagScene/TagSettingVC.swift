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
        
        tagService.fetchTags()
        tableView.reloadData()
    }
    
    
    @objc func addBtnTapped() {
        // 수정 팝업 띄우기
        let alert = UIAlertController(title: "Add New Tag", message: nil, preferredStyle: .alert)
        alert.addTextField()
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self]_ in
            if let textField = alert.textFields?.first, let newText = textField.text, !newText.isEmpty {
                guard let self else { return }
                tagService.addNewTag(newText)
                tableView.reloadData()
            }
        }
        alert.addAction(saveAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    //MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tagService.tags.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(TagListItemCell.self)", for: indexPath) as? TagListItemCell else
        {return UITableViewCell()}
        let item = tagService.tags[indexPath.row]
        cell.nameLabel.text =  item.name
        cell.countLabel.text = "(" + String(describing: item.filePaths.count)  + ")"
        return cell
    }
    
    //MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        //쓸어서 삭제 기능
        let deleteAction = UIContextualAction(style: .destructive, title: "삭제(Delete)"){ [weak self] action, view, completion in
            guard let self else { return }
            tagService.deleteTag(at: indexPath.row)
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
            textField.text = self.tagService.tags[indexPath.row].name
        }
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self]_ in
            if let textField = alert.textFields?.first, let newText = textField.text,
               !newText.isEmpty {
                guard let self else { return }
                tagService.editTagName(at: indexPath.row, newName: newText)
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        }
        alert.addAction(saveAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDragDelegate
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let item = tagService.tags[indexPath.row]._id.stringValue
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
                
                tagService.editTagOrder(at: sourceIndexPath.row, to: destinationIndexPath.row)
                
                tableView.performBatchUpdates({
                
                    tableView.deleteRows(at: [sourceIndexPath], with: .automatic)
                    tableView.insertRows(at: [destinationIndexPath], with: .automatic)
                })
                
                coordinator.drop(item.dragItem, toRowAt: destinationIndexPath)
            }
        }
    }

}
