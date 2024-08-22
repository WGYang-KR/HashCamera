//
//  TagListItemCell.swift
//  HashCamera
//
//  Created by Anto-Yang on 8/5/24.
//

import UIKit

class TagListItemCell: UITableViewCell {

    @IBOutlet weak var selectedImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    
    let normalColor = UIColor(resource: .colorTeal02)
    let selectedColor = UIColor(resource: .colorTeal01)
    let normalFont = UIFont.systemFont(ofSize: 17.0, weight: .regular)
    let selectedFont = UIFont.systemFont(ofSize: 17.0, weight: .bold)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        selectedImageView.isHidden = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        nameLabel.font = selected ? selectedFont : normalFont
        nameLabel.textColor = selected ? selectedColor : normalColor
        selectedImageView.isHidden = !selected
    }
    
}
