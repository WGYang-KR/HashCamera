//
//  FolderListItemCell.swift
//  HashCamera
//
//  Created by Anto-Yang on 8/5/24.
//

import UIKit

class FolderListItemCell: UITableViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    let normalTextColor: UIColor = .secondaryLabel
    let selectedTextColor: UIColor = .white
    
    let selectedBoxColor: UIColor = .color01
   
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .blue
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
//        nameLabel.textColor = selected ? selectedTextColor : normalTextColor
//        iconImageView.tintColor = selected ? selectedTextColor : normalTextColor
//        selectedBoxView.backgroundColor = selected ? selectedBoxColor : .clear
        
    }
    
}
