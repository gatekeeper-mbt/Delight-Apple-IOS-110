//
//  MyTableViewCell.swift
//  hangge_1040
//
//  Created by hangge on 16/1/23.
//  Copyright © 2016年 hangge.com. All rights reserved.
//

import UIKit

class MyTableViewCell: UITableViewCell {
    var refreshControl: UIRefreshControl!
    
    @IBOutlet weak var customView: UIView!
    @IBOutlet weak var customLabel: UILabel!
    @IBOutlet weak var customImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        //设置cell是有圆角边框显示
        customView.layer.cornerRadius = 8
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }    
}
