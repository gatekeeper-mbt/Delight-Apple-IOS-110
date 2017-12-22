//
//  AboutViewController.swift
//  Delight
//
//  Created by mac on 2017/7/15.
//  Copyright © 2017年 mac. All rights reserved.
//

import UIKit

class AboutViewController: BaseViewController {
    deinit {
        // perform the deinitialization
        print("About is dead")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.addSlideMenuButton()
        print("AboutViewController")
        self.title = "About"
     }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        print("AboutViewDidDisappear")
    }

}
