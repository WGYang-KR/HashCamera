//
//  MoveToFolderListItemCell.swift
//  HashCamera
//
//  Created by Anto-Yang on 9/23/24.
//

import UIKit

class MoveToFolderListItemCell: UITableViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        iconImageView.isHidden = !selected
    }
    
}
