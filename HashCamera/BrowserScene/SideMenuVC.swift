//
//  SideMenuVC.swift
//  HashCamera
//
//  Created by Anto-Yang on 7/18/24.
//

import UIKit

class SideMenuVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let tagService = TagService.shared
    @IBOutlet weak var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let naviSettingBarBtnItem = UIBarButtonItem(image: SystemUIImage.gearshape,
                                                    style: .plain,
                                                    target: self,
                                                    action: #selector(settingBtnTapped))
        
        setNaviBar("Tags", leftItems: [naviSettingBarBtnItem], rightItems:nil)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "\(TagListItemCell.self)", bundle: nil), forCellReuseIdentifier: "\(TagListItemCell.self)")
 
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tagService.fetchTags()
        tableView.reloadData()
    }
    
    @IBAction func settingBtnTapped(_ sender: Any) {
        presentFull(UINavigationController(rootViewController: TagSettingVC()), animated: true)
    }
    
    //MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tagService.tags.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(TagListItemCell.self)", for: indexPath) as? TagListItemCell else
        {return UITableViewCell()}
        let item = tagService.tags[indexPath.row]
        cell.line3ImageView.isHidden = true
        cell.nameLabel.text =  item.name
        cell.countLabel.text = "(" + String(describing: item.filePaths.count)  + ")"
        return cell
    }
    
    //MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    
}
