//
//  InfoTableViewCell.swift
//  Delight
//
//  Created by mac on 2017/9/1.
//  Copyright © 2017年 mac. All rights reserved.
//

import UIKit

class InfoTableViewCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var characteristic: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
