//
//  ListVC.swift
//  WavLite
//
//  Created by Jim Aven on 7/28/15.
//  Copyright (c) 2015 Jim Aven. All rights reserved.
//

import UIKit
import Parse


class ListVC: UIViewController, UITableViewDataSource, UITableViewDelegate, LiquidFloatingActionButtonDataSource, LiquidFloatingActionButtonDelegate {
    
    @IBOutlet weak var noListLabel: UILabel!
    var tableList = [String]()
    
    @IBOutlet weak var tableView: UITableView!
    
    var hasList = false
    
    //Liquid cells setup
    var cells:[LiquidFloatingCell] = []
    var floatingCell: LiquidFloatingActionButton!
    var floatingBtnImg:UIImage!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        isDataAvailable()
        self.tableView.reloadData()
        
        // Liquid floating button add
        setupLiquidTouch()
        
        
    }
    
    override func viewWillAppear(animated: Bool) {
        
        self.tableView.reloadData()
        if curUser == nil {
            self.tabBarController?.selectedIndex = 0
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "toDetailSegue"{
            let vc:DetailListVC = segue.destinationViewController as! DetailListVC
            let indexPath = self.tableView.indexPathForSelectedRow
            let videoList:PFObject = gParseList![indexPath!.row]
            vc.videos = videoList
        }
    }
    
    @IBAction func btnBackPressed(sender: AnyObject) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: Tableview funcs
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        if self.hasList {
            
        }
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
        
        if self.hasList {
            return gParseList!.count
        }
        else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if self.hasList {
            
            let cell:ListCell = tableView.dequeueReusableCellWithIdentifier("listCell") as! ListCell
        
            let path:PFObject = gParseList![indexPath.row]
            
            let titleText:String = path["listTitle"] as! String

             cell.titleLabel.text = titleText
            
            return cell
        }
        else {
            return UITableViewCell()
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let curList:PFObject = gParseList![indexPath.row]
        let list:AnyObject? = curList["myLists"]
        if list == nil {
            let alert:UIAlertView = UIAlertView(title: "Oops", message: "You have no videos in this list", delegate: self, cancelButtonTitle: "Ok")
            alert.show()
        }
        else {
            
            self.performSegueWithIdentifier("toDetailSegue", sender: self)
        }
     }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == UITableViewCellEditingStyle.Delete {
            
            let alert = UIAlertController(title: "Are you sure you want to delete?", message: "", preferredStyle: .Alert)
            let deleteAction = UIAlertAction(title: "Delete", style: .Destructive, handler: { (UIAlertAction) -> Void in
              
                let title = gParseList![indexPath.row].objectId
                gParseList?.removeAtIndex(indexPath.row)
                let api = APIRequests()
                api.removeUserList(title!)
                self.tableView.reloadData()
                
            })
            alert.addAction(deleteAction)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Default, handler: nil)
            alert.addAction(cancelAction)
            self.addChildViewController(alert)
        }
        
        if editingStyle == UITableViewCellEditingStyle.Insert {
            
        }
    }
    
    //MARK: TableView data and delegate
    
    func isDataAvailable(){
        
        if gParseList == nil {
            self.hasList = false
            self.noListLabel.hidden = false
            self.tableView.hidden = true
        }
        else {
            self.hasList = true
            self.noListLabel.hidden = true
            self.tableView.hidden = false
        }
        
    }
    
    //MARK: LiquidBtn funcs
    
    func numberOfCells(liquidFloatingActionButton: LiquidFloatingActionButton) -> Int {
        return self.cells.count
    }
    func cellForIndex(index: Int) -> LiquidFloatingCell {
        return self.cells[index]
    }
    
    func liquidFloatingActionButton(liquidFloatingActionButton: LiquidFloatingActionButton, didSelectItemAtIndex index: Int) {
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        var story:String!
        
        
        if index == 0 {
            
            PFUser.logOut()
            curUser = nil
            
            self.dismissViewControllerAnimated(true, completion: nil)
            story = "homeVC"
            
        }
        else if index == 1 {
            story = "searchVC"
        }
        else if index == 2 {
            story = "homeVC"
        }
        else {
            createNewList()
        }
        
        if story != nil {
            let vc = storyBoard.instantiateViewControllerWithIdentifier(story)
            self.presentViewController(vc, animated: true, completion: nil)
        }
        
        liquidFloatingActionButton.close()
    }
    
    func setupLiquidTouch () {
        
        let liquidBtn = LiquidFloatingActionButton(frame: CGRect(x: self.view.frame.width - 45 - 20, y: self.view.frame.height - 45 - 20, width: 45, height:45))
        
        liquidBtn.delegate = self
        liquidBtn.dataSource = self
        
        // buttons for liquid menu in ord they appear
        let addNewListCell = LiquidFloatingCell(icon: UIImage(named: "btn_add.png")!)
        let toHomeCell = LiquidFloatingCell(icon: UIImage(named: "btn_home.png")!)
        let toSearchCell = LiquidFloatingCell(icon: UIImage(named: "btn_search.png")!)
        let logoutCell = LiquidFloatingCell(icon: UIImage(named: "btn_logout.png")!)
        
        self.cells.append(logoutCell)
        self.cells.append(toSearchCell)
        self.cells.append(toHomeCell)
        self.cells.append(addNewListCell)
        
        self.view.addSubview(liquidBtn)
    }
    
    func createNewList () {
        
        var aTextField:UITextField?
        
        let alert = UIAlertController(title: "Create List", message: "Type your list title", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addTextFieldWithConfigurationHandler { (text:UITextField) -> Void in
            
            aTextField = text
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alert.addAction(cancelAction)
        
        let saveAction = UIAlertAction(title: "Save", style: .Default) { (UIAlertAction) -> Void in
            let API = APIRequests()
            
            if let inputTitle = aTextField?.text {
                
                API.createListTitle(inputTitle, vidId: nil)
            }
        }
        
        alert.addAction(saveAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
}
