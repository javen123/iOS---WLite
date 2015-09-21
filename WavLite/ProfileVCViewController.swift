//
//  ProfileVCViewController.swift
//  WavLite
//
//  Created by Jim Aven on 9/9/15.
//  Copyright (c) 2015 Jim Aven. All rights reserved.
//

import UIKit

class ProfileVCViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func logoutBtnPressed(sender: AnyObject) {
        
        self.tabBarController?.selectedIndex = 0
        
    }

    
}
