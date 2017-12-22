//
//  TableViewCell.swift
//  Delight
//
//  Created by mac on 2017/7/26.
//  Copyright © 2017年 mac. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {

    @IBOutlet weak var customView: UIView!
    @IBOutlet weak var customLabel: UILabel!
    @IBOutlet weak var customImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        customView.layer.cornerRadius = 8
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
