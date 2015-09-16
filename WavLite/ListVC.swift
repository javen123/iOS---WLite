//
//  ListVC.swift
//  WavLite
//
//  Created by Jim Aven on 7/28/15.
//  Copyright (c) 2015 Jim Aven. All rights reserved.
//

import UIKit
import Parse


class ListVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var tableList = [String]()
    
    @IBOutlet weak var tableView: UITableView!
    @IBAction func playBtnPressed(sender: AnyObject) {
        self.performSegueWithIdentifier("toPlayerSegue", sender: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

//        convertListToTitleTableArray(gParseList)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "toDetailSegue"{
            let vc:DetailListVC = segue.destinationViewController as! DetailListVC
            let indexPath = self.tableView.indexPathForSelectedRow()
            let videoList:PFObject = gParseList[indexPath!.row]
            vc.videos = videoList
        }
    }
    
    //MARK: TableView data and delegate
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        var x:CGFloat!
        if self.tableList.count >= 10 {
            x = 30
        }
        else {
            x = 60
        }
        return x
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return gParseList.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:ListCell = tableView.dequeueReusableCellWithIdentifier("listCell") as! ListCell
        
        let path:PFObject = gParseList[indexPath.row]
        
        let titleText:String = path["listTitle"] as! String

         cell.titleLabel.text = titleText
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let curList:PFObject = gParseList[indexPath.row]
        let list:AnyObject? = curList["myLists"]
        if list == nil {
            let alert:UIAlertView = UIAlertView(title: "Oops", message: "You have no videos in this list", delegate: self, cancelButtonTitle: "Ok")
            alert.show()
        }
        else {
            self.performSegueWithIdentifier("toDetailSegue", sender: self)
        }
     }
}
