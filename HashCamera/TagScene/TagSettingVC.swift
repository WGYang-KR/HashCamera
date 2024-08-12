//
//  TagSettingVC.swift
//  HashCamera
//
//  Created by Anto-Yang on 7/22/24.
//

import UIKit

class TagSettingVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let tagService = TagService.shared
    @IBOutlet weak var tableView: UITableView!
    
    var items: [String] = ["Item 1", "Item 2", "Item 3", "Item 4"]

      override func viewDidLoad() {
          super.viewDidLoad()

          tableView.delegate = self
          tableView.dataSource = self

          navigationItem.rightBarButtonItem = self.editButtonItem
          
          tableView.register(UINib(nibName: "\(TagListItemCell.self)", bundle: nil), forCellReuseIdentifier: "\(TagListItemCell.self)")

          setNaviBar("태그 관리")
      }

      // 데이터 소스 메서드
      func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
          return items.count
      }

      func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
          guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(TagListItemCell.self)", for: indexPath) as? TagListItemCell else
          {return UITableViewCell()}
          cell.nameLabel.text = items[indexPath.row]
          return cell
      }

      // 삭제 기능
      func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
          if editingStyle == .delete {
              items.remove(at: indexPath.row)
              tableView.deleteRows(at: [indexPath], with: .fade)
          }
      }

      // 순서 변경 기능
      func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
          let movedItem = items.remove(at: sourceIndexPath.row)
          items.insert(movedItem, at: destinationIndexPath.row)
      }

    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return true
    }
      // 수정 팝업 띄우기
      func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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

}
