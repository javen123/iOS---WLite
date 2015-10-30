//
//  SearchViewVC.swift
//  WavLite
//
//  Created by Jim Aven on 9/15/15.
//  Copyright (c) 2015 Jim Aven. All rights reserved.
//

import UIKit
import SwiftyJSON
import Swift_YouTube_Player


class SearchViewVC: UIViewController,UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, LiquidFloatingActionButtonDataSource, LiquidFloatingActionButtonDelegate {
    
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var playerView: YouTubePlayerView!
    
    var vidId:String?
    
    var genreSearch:String?
    
    //Liquid cells setup
    var cells:[LiquidFloatingCell] = []
    var floatingCell: LiquidFloatingActionButton!
    var floatingBtnImg:UIImage!
   
    var ytAPILists:[VideoItem] = [VideoItem]()
    var playerActive = false
    
    let API = APIRequests()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //genre search 
        
        let prefs = NSUserDefaults.standardUserDefaults()
        if prefs.objectForKey("GENREKEY") != nil {
            self.genreSearch = prefs.objectForKey("GENREKEY") as? String
        }
        
        // searchbar setup
        
        searchBar.placeholder = "Enter your search here"
        
        // youtube player set up
        
        self.playerView.hidden = true
        
        // Liquid floating button add
        setupLiquidTouch()
        
        //tableview long press aet up
        
        let longPress = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        self.tableView.addGestureRecognizer(longPress)
        
        //activity indecator setup
        self.activityIndicator.color = UIColor.whiteColor()
        self.activityIndicator.hidden = true
        self.activityIndicatorAction()

    }
    
    override func viewDidDisappear(animated: Bool) {
        if changesMade == true {
            self.API.convertUserListsToParseObjectsAndSaveToParse()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        
        tableView.hidden = true
        self.activityIndicator.hidden = true
        self.activityIndicatorAction()
        if let genre = self.genreSearch{
            API.genericYtListPull(genre)
            let prefs = NSUserDefaults.standardUserDefaults()
            prefs.setValue(nil, forKeyPath: "GENREKEY")
        }
        else {
            API.genericYtListPull("top+music")
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "convertYtApiInfoToCell:", name: "ULFINISHED", object: nil)
    }
    
    //MARK: TableView info
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 65
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 65
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell:SearchCell = tableView.dequeueReusableCellWithIdentifier("searchCell") as! SearchCell
        let data = ytAPILists[indexPath.row]
        
       // set cell image
        let imageString = data.picURL
        if let url = NSURL(string: imageString){
            if let data = NSData(contentsOfURL: url){
                cell.ytCellImage.image = UIImage(data: data)
            }
        
            
            //set cell title
            let title = data.videoTitle
            cell.ytCellTitle.text = title
            tableView.hidden = false
            self.activityIndicator.hidden = false
            self.activityIndicatorAction()
        }
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return ytAPILists.count
    }
    
    //MARK: table View delegates
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        self.playerActive = true
        
        self.vidId = ytAPILists[indexPath.row].videoId
        
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
        let cell = ytAPILists[indexPath!.row]
        vidId = cell.videoId
        let vidTitle = cell.videoTitle
        
        if state == .Began {
            // implement alerts
            addTitleToListSheet(vidId!, vidTitle: vidTitle)
        }
    }
    
    @IBAction func btnBackPressed(sender: AnyObject) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: HELPERS
    
    func convertYtApiInfoToCell(notification:NSNotification){
        
        for (_, value): (String, JSON) in gJson!["items"] {
           
            var id:String
            if value["id"]["playlistId"] != nil{
                id = value["id"]["playlistId"].stringValue
            }
            else {
               id = value["id"]["videoId"].stringValue
            }
            
            let vidTitle = value["snippet"]["title"].stringValue
            let vidDes = value["snippet"]["description"].stringValue
            let url = value["snippet"]["thumbnails"]["default"]["url"].stringValue
            let vidInfo = VideoItem(vidId: id, vidTitle: vidTitle, vidDesc: vidDes, vidPic: url)
            ytAPILists.append(vidInfo)
        }
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.tableView.reloadData()
        })
        
    }

    //MARK: SearchBar funcs
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchText.characters.count > 3 {
            let tmp = searchText.stringByReplacingOccurrencesOfString(" ", withString: "+")
            ytAPILists.removeAll(keepCapacity: false)
            API.genericYtListPull(tmp)
        }
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    //MARK: Alerts
    
    func addTitleToListSheet(vidId:String, vidTitle: String) {
        
        var alertSheet:UIAlertController?
        
        if userLists.count > 0 {
            
            alertSheet = UIAlertController(title: vidTitle, message: "Choose list", preferredStyle: UIAlertControllerStyle.ActionSheet)
                
                for x in userLists{
                    
                    let title = x.title
                    let action = UIAlertAction(title: title, style: .Default, handler: { (UIAlertAction) -> Void in
                        
                        x.addNewTitle(vidId)
                        changesMade = true
                        self.addSingleTitleAlertHelper()
                    })
                    
                    
                    alertSheet?.addAction(action)
                }
                let createAction = UIAlertAction(title: "Create New List", style: UIAlertActionStyle.Destructive, handler: { (UIAlertAction) -> Void in
                    
                    self.createNewList()
                    
                })
                alertSheet?.addAction(createAction)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            alertSheet?.addAction(cancelAction)
            self.presentViewController(alertSheet!, animated: true, completion: nil)

            
            } else {
                
                self.createNewList()
            }
    }

    func addSingleTitleAlertHelper(){
        
        
            let alert = UIAlertController(title: "Success", message: "Your video has been added", preferredStyle: UIAlertControllerStyle.Alert)
            let cancelAction = UIAlertAction(title: "Ok", style: .Default, handler: nil)
            alert.addAction(cancelAction)
            self.presentViewController(alert, animated: true, completion: nil)
      
            
        
       
    }
    
        func activityIndicatorAction(){
        
        if self.activityIndicator.hidden == false {
            self.activityIndicator.stopAnimating()
            self.activityIndicator.hidesWhenStopped = true
        }
        else {
            self.activityIndicator.hidden = true
            self.activityIndicator.hidden = false
            self.activityIndicator.startAnimating()
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
            story = "homeVC"
        }
        else if index == 2 {
            story = "listVC"
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
        let toListsCell = LiquidFloatingCell(icon: UIImage(named: "btn_lists.png")!)
        let toHomeCell = LiquidFloatingCell(icon: UIImage(named: "btn_home.png")!)
        let logoutCell = LiquidFloatingCell(icon: UIImage(named: "btn_logout.png")!)
        
        self.cells.append(logoutCell)
        self.cells.append(toHomeCell)
        self.cells.append(toListsCell)
        self.cells.append(addNewListCell)
        
        self.view.addSubview(liquidBtn)
    }
    
    func createNewList () {
        
        var aTextField:UITextField?
        
        var title:String!
        var message:String!
        
        if userLists.count > 0 {
            title = "Create New List"
            message = ""
            
        } else {
            title = "Create your first list"
            message = "Once created you can add this video to the list"
        }
        
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addTextFieldWithConfigurationHandler { (text:UITextField) -> Void in
            
            aTextField = text
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alert.addAction(cancelAction)
        
        let saveAction = UIAlertAction(title: "Save", style: .Default) { (UIAlertAction) -> Void in
            
            
            if let inputTitle = aTextField?.text {
                
                self.API.createListTitle(inputTitle, vidId: nil, completed: { () -> () in
                    return
                })
            }
        }
        
        alert.addAction(saveAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
}
