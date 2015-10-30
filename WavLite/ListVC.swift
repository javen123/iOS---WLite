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
    @IBOutlet weak var tableView: UITableView!
    
    //Liquid cells setup
    var cells:[LiquidFloatingCell] = []
    var floatingCell: LiquidFloatingActionButton!
    var floatingBtnImg:UIImage!
    var deletedListName:[String]!
    
    let API = APIRequests()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.tableView.reloadData()
        isDataAvailable()
        // Liquid floating button add
        setupLiquidTouch()
        
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        
        if changesMade == true {
            API.convertUserListsToParseObjectsAndSaveToParse()
        }
        
        if self.deletedListName != nil {
            API.removeUserList(self.deletedListName)
           
            
            self.deletedListName.removeAll()
        }
    }
    override func viewDidAppear(animated: Bool) {
        tableView.reloadData()
        isDataAvailable()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "toDetailSegue"{
            let vc:DetailListVC = segue.destinationViewController as! DetailListVC
            let indexPath = self.tableView.indexPathForSelectedRow?.row
            vc.listIndex = indexPath
        }
    }
    
    @IBAction func btnBackPressed(sender: AnyObject){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    //MARK: Tableview funcs
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        var x:CGFloat!
        if userLists.count >= 10 {
            x = 60
        }
        else {
            x = 80
        }
        return x
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
            return userLists.count
    
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        
        let cell:ListCell = tableView.dequeueReusableCellWithIdentifier("listCell") as! ListCell
        
        let title = userLists[indexPath.row].title
            cell.titleLabel.text = title
            return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let curList = userLists[indexPath.row].lists
        
        if curList.count == 0 {
            
            let alert = UIAlertController(title: "Oops", message: "You have no videos in this list", preferredStyle: UIAlertControllerStyle.Alert)
            let cancelAction = UIAlertAction(title: "Ok", style: .Default, handler: nil)
            alert.addAction(cancelAction)
            self.presentViewController(alert, animated: true, completion: nil)
        }
        else {
            
            self.performSegueWithIdentifier("toDetailSegue", sender: self)
        }
     }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == UITableViewCellEditingStyle.Delete {
            
            let alert = UIAlertController(title: "Are you sure you want to delete?", message: "", preferredStyle: .Alert)
            let deleteAction = UIAlertAction(title: "Delete", style: .Destructive, handler: { (UIAlertAction) -> Void in
              
                self.deletedListName = [String]()
                self.deletedListName.append(userLists[indexPath.row].title)
                userLists.removeAtIndex(indexPath.row)
                self.tableView.reloadData()
                self.isDataAvailable()
            })
            alert.addAction(deleteAction)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Default, handler: nil)
            alert.addAction(cancelAction)
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
    }
    
    //MARK: TableView data and delegate
    
    func isDataAvailable(){
        
        if userLists.count == 0 {
           
            self.noListLabel.hidden = false
            self.tableView.hidden = true
        }
        else {
            
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
                
                API.createListTitle(inputTitle, vidId: nil, completed: { () -> () in
                    
                    self.tableView.reloadData()
                })
            }
        }
        
        alert.addAction(saveAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
}
