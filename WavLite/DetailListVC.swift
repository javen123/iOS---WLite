//
//  DetailListVC.swift
//  WavLite
//
//  Created by Jim Aven on 8/5/15.
//  Copyright (c) 2015 Jim Aven. All rights reserved.
//

import UIKit
import Parse
import SwiftyJSON
import Swift_YouTube_Player


class DetailListVC: UIViewController, UITableViewDataSource, UITableViewDelegate, LiquidFloatingActionButtonDelegate, LiquidFloatingActionButtonDataSource {
    
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var playerView: YouTubePlayerView!
    @IBOutlet weak var navBar: UINavigationBar!
    
    //Liquid cells setup
    var cells:[LiquidFloatingCell] = []
    var floatingCell: LiquidFloatingActionButton!
    var floatingBtnImg:UIImage!
    
    var listIndex:Int!
    
    var vidId:String?
    var vidInfo = [VideoItem]()
    var vidIds:String!
   
    var playerActive = false
    
    let API = APIRequests()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        convertPFObjectToYouTubeList(videos)
        vidIds = userLists[listIndex].lists.joinWithSeparator(",")
        self.navBar.topItem?.title = userLists[listIndex].title
        
        self.playerView.hidden = true
        
        // Liquid floating button add
        setupLiquidTouch()
        
        //tableview long press aet up
        
        let longPress = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        self.tableView.addGestureRecognizer(longPress)
        
        // activity indicator 
        self.activityIndicator.color = UIColor.whiteColor()
        self.activityIndicator.hidden = true
        self.activityIndicatorAction()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        tableView.hidden = true
        self.API.userYTListPull(vidIds)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "convertYtApiInfoToCell:", name: "YTFINISHED", object: nil)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func bakcBtnPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    //MARK: TableView data and delegate
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 65
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 65
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell:DetailListCell = tableView.dequeueReusableCellWithIdentifier("detailCell") as! DetailListCell
        let data = vidInfo[indexPath.row]
        
        // set cell image
        let imageString = data.picURL
        if let url = NSURL(string: imageString){
            if let data = NSData(contentsOfURL: url){
                cell.detailCellImage.image = UIImage(data: data)
            }
        }
        
        //set cell title
        let title = data.videoTitle
        cell.detailTitleTextLabel.text = title
       
        self.activityIndicator.hidden = false
        self.activityIndicatorAction()
        tableView.hidden = false
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return vidInfo.count
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        self.playerActive = true
        
        self.vidId = self.vidInfo[indexPath.row].videoId
        
        if (self.vidId!).characters.count <= 11 {
            self.playerView.loadVideoID(self.vidId!)
            
        }
        else {
            self.playerView.loadPlaylistID(self.vidId!)
        }
        
        self.playerView.hidden = false
        
        // set up tap for player view
        let tap = UITapGestureRecognizer(target: self, action: "handleTap:")
        self.view.addGestureRecognizer(tap)
        
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == UITableViewCellEditingStyle.Delete {
            
            self.confirmDeleteOfVideo(indexPath.row)
        }
    }
    
    
    //MARK: Handle Taps
    
    func handleTap(tap:UITapGestureRecognizer){
        
        if self.playerActive == true {
            self.playerView.hidden = true
            self.playerActive = false
            self.view.removeGestureRecognizer(tap)
        }
    }
    
    func handleLongPress(press: UILongPressGestureRecognizer){
        
        let state = press.state
        let locationView = press.locationInView(self.tableView)
        let indexPath = self.tableView.indexPathForRowAtPoint(locationView)
        let cell = vidInfo[indexPath!.row]
        vidId = cell.videoId
        let vidTitle = cell.videoTitle
        if state == .Began {
            self.editTitleInList(vidTitle, id:vidId!, index:(indexPath!.row))
        }
    }


    
    //MARK:Helpers
    
    func convertVidInfoToYTApiCallList (items:[VideoItem]) -> [String] {
        
        var temp:[String] = []
        
        for x in items {
            let y = x.videoId
            temp.append(y)
        }
        if temp.count > 1 {
            temp.joinWithSeparator(",")
        }
        
        return temp
    }
    
    func convertYtApiInfoToCell(notification:NSNotification){
        
        for (_, value): (String, JSON) in gJson!["items"] {
            
            let items = value
            
            let id = items["id"].stringValue
            
            let vidTitle = items["snippet"]["title"].stringValue
            let vidDes = items["snippet"]["description"].stringValue
            let url = items["snippet"]["thumbnails"]["default"]["url"].stringValue
            let vidInfo = VideoItem(vidId: id, vidTitle: vidTitle, vidDesc: vidDes, vidPic: url)
            self.vidInfo.append(vidInfo)
        }

        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.tableView.reloadData()
        })
    }
    
    //MARK: Alerts
    
    func editTitleInList(vidTitle: String, id:String, index:Int) {
        
         let alert = UIAlertController(title: vidTitle, message: "Edit this item?", preferredStyle: .Alert)
        
        
        // add copy to action
        
        let copyToAction = UIAlertAction(title: "Copy to", style: .Default) { (UIAlertAction) -> Void in
            
            self.addTitleToListSheet(id, vidTitle: vidTitle, completed: { () -> () in
                self.addSingleTitleAlertHelper()
                changesMade = true
            })
            
        }
        
        alert.addAction(copyToAction)
        
        // add move to action
        
        let moveToAction = UIAlertAction(title: "Move to", style: .Default) { (UIAlertAction) -> Void in
            
            self.moveTitleToListSheet(id, vidTitle: vidTitle, index: index)
            changesMade = true
            
        }
        alert.addAction(moveToAction)
        
        // add delete action
        
        let deleteAction = UIAlertAction(title: "Delete", style: .Destructive) { (UIAlertAction) -> Void in
            
            self.confirmDeleteOfVideo(index)
            
        }
        
        alert.addAction(deleteAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Default, handler: nil)
        alert.addAction(cancelAction)
        
        self.presentViewController(alert, animated: true, completion:nil)
        
    }
    
    func confirmDeleteOfVideo(index:Int){
        
        let alert = UIAlertController(title: "Are you Sure?", message: "Your video will be deleted", preferredStyle: UIAlertControllerStyle.Alert)
        let deleteAction = UIAlertAction(title: "Delete", style: .Destructive) { (UIAlertAction) -> Void in
            
            userLists[self.listIndex].removeVideoAtIndex(index)
            self.vidInfo.removeAtIndex(index)
            changesMade = true
            self.tableView.reloadData()
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Default, handler: nil)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        self.presentViewController(alert, animated: true, completion: nil)

    }
    
    func addSingleTitleAlertHelper(){
        
        
            let alert = UIAlertController(title: "Success", message: "Your video has been added", preferredStyle: UIAlertControllerStyle.Alert)
            let cancelAction = UIAlertAction(title: "Ok", style: .Default, handler: nil)
            alert.addAction(cancelAction)
            self.presentViewController(alert, animated: true, completion: nil)
    }
  
    // Copy Alert helper
    
    func addTitleToListSheet(vidId:String, vidTitle: String, completed:AlertOrder) {
        
        var alertSheet:UIAlertController!
        
        if userLists.count > 0 {
            
            alertSheet = UIAlertController(title: vidTitle, message: "Choose list", preferredStyle: UIAlertControllerStyle.ActionSheet)
            
            for x in userLists{
                
                let title = x.title
                
                let action = UIAlertAction(title: title, style: .Default, handler: { (UIAlertAction) -> Void in
                    
                    x.addNewTitle(vidId)
                    completed()
                })
                alertSheet.addAction(action)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Destructive, handler: nil)
        alertSheet.addAction(cancelAction)
        self.presentViewController(alertSheet, animated: true, completion: nil)
    }
    
    // Move title to another list
    
    func moveTitleToListSheet(vidId:String, vidTitle: String, index:Int) {
        
        addTitleToListSheet(vidId, vidTitle: vidTitle) { () -> () in
            
            let alert = UIAlertController(title: "Video Moved", message: "", preferredStyle: UIAlertControllerStyle.Alert)
            let cancelAction = UIAlertAction(title: "Ok", style: .Default, handler: nil)
            alert.addAction(cancelAction)
            self.presentViewController(alert, animated: true, completion: nil)
            self.tableView.reloadData()

        }
        
        userLists[listIndex].removeVideoAtIndex(index)
        
        vidInfo.removeAtIndex(index)
        
               
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
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: "SIGNEDIN")
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
                    return
                })
             }
        }
        
        alert.addAction(saveAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }

    func activityIndicatorAction(){
        
        if self.activityIndicator.hidden == false {
            self.activityIndicator.hidden = true
            self.activityIndicator.stopAnimating()
        }
        else {
            self.activityIndicator.hidden = false
            self.activityIndicator.startAnimating()
        }
        
    }
}
