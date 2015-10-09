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

    
    var vidId:String?
    var videos:PFObject!
    var vidInfo = [VideoItem]()
    var vidIds:String!
   
    var playerActive = false
    
    let API = APIRequests()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        convertPFObjectToYouTubeList(videos)
        vidIds = convertPFObjectToYouTubeList(videos)
        self.navBar.topItem?.title = videos["listTitle"] as? String
        
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
    @IBAction func logOutBtnPressed(sender: AnyObject) {
        
        PFUser.logOut()
        curUser = nil
        self.dismissViewControllerAnimated(true, completion: nil)
        self.tabBarController?.selectedIndex = 0
        
        
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
            
            self.vidInfo.removeAtIndex(indexPath.row)
            let ids = convertVidInfoToYTApiCallList(vidInfo)
            let listId:String = self.videos.objectId!
//            let api = APIRequests()
            print(vidInfo)
            self.API.addUpdateItemToUserList(listId, newList: ids)
            self.tableView.reloadData()
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
            self.editTitleInList(vidTitle, id:vidId!)
        }
    }


    
    //MARK:Helpers
    
    func convertPFObjectToYouTubeList(object:PFObject) -> String? {
        
        var temp:String!
        
        if let list:[String] = object["myLists"] as? [String]{
            if list.count > 1 {
                temp = list.joinWithSeparator(",")
            }
            else {
                temp = list[0]
            }
        }
        print("temp list is: \(temp)")
        return temp
    }
    
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
            
            print("Vid id is : \(id)")
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
    
    func editTitleInList(vidTitle: String, id:String) {
        
         let alert = UIAlertController(title: vidTitle, message: "Edit this item?", preferredStyle: .Alert)
        
        
        // add copy to action
        
        
        let copyToAction = UIAlertAction(title: "Copy to", style: .Default) { (UIAlertAction) -> Void in
            
            if self.presentedViewController == nil {
                print("it is nil")
                self.addTitleToListSheet(id, vidTitle: vidTitle)
            }
        }
        
        alert.addAction(copyToAction)
        
        // add move to action
        
        let moveToAction = UIAlertAction(title: "Move to", style: .Default) { (UIAlertAction) -> Void in
            
            
        }
        alert.addAction(moveToAction)
        
        // add delete action
        
        let deleteAction = UIAlertAction(title: "Delete", style: .Destructive) { (UIAlertAction) -> Void in
            
            
        }
        
        alert.addAction(deleteAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Default, handler: nil)
        alert.addAction(cancelAction)
        
        self.presentViewController(alert, animated: true, completion:nil)
        
    }
    
    func addSingleTitleAlertHelper(success:Bool){
        
        if success {
            
            let alert = UIAlertController(title: "Success", message: "Your video has been added", preferredStyle: UIAlertControllerStyle.Alert)
            let cancelAction = UIAlertAction(title: "Ok", style: .Default, handler: nil)
            alert.addAction(cancelAction)
            self.presentViewController(alert, animated: true, completion: nil)
        }
        else {
            
            let alert = UIAlertController(title: "Oops", message: "You may have to try that again", preferredStyle: UIAlertControllerStyle.Alert)
            let cancelAction = UIAlertAction(title: "Ok", style: .Default, handler: nil)
            alert.addAction(cancelAction)
            self.presentViewController(alert, animated: true, completion: nil)
        }
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
    
    // Copy Alert helper
    
    func addTitleToListSheet(vidId:String, vidTitle: String) {
        
        
        var id:String!
        
        if let objects = gParseList {
            
            let alertSheet = UIAlertController(title: vidTitle, message: "Choose list", preferredStyle: UIAlertControllerStyle.ActionSheet)
            
            for x in objects{
                id = x.objectId
                var myLists:[String] = x["myLists"] as! [String]
                let title:String = x.valueForKey("listTitle") as! String
                let action = UIAlertAction(title: title, style: .Default, handler: { (UIAlertAction) -> Void in
                    
                    myLists.append(vidId)
                    
                    self.API.addUpdateItemToUserList(id!, newList: myLists)
                    
                    //TODO:Figue out synchronous call before showing alert
                    
                    self.addSingleTitleAlertHelper(true)
                })
                
                alertSheet.addAction(action)
            }
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
        if index == 0 {
            createNewList()
        }
        liquidFloatingActionButton.close()
    }
    
    func setupLiquidTouch () {
        
        let liquidBtn = LiquidFloatingActionButton(frame: CGRect(x: self.view.frame.width - 56 - 26, y: self.view.frame.height / 2, width: 56, height:56))
        
        liquidBtn.delegate = self
        liquidBtn.dataSource = self
        let addNewListCell = LiquidFloatingCell(icon: UIImage(named: "btn_add.png")!)
        
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
            
            if let inputTitle = aTextField?.text {
                
                self.API.createListTitle(inputTitle, vidId: nil)
            }
        }
        
        alert.addAction(saveAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
}
