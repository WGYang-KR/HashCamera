//
//  BrowserItemCell.swift
//  HashCamera
//
//  Created by WG-MacHome on 11/28/23.
//

import UIKit

class BrowserItemCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var selectionCoverView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        
        selectionCoverView.isHidden  = !state.isSelected 
    }
}
