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


class SearchViewVC: UIViewController,UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var playerView: YouTubePlayerView!
    
    var vidId:String?
   
    var ytAPILists:[VideoItem] = [VideoItem]()
    var playerActive = false
    
    let API = APIRequests()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // searchbar setup
        
        searchBar.placeholder = "Enter your search here"
        
        // youtube player set up
        
        self.playerView.hidden = true
        
        //tableview long press aet up
        
        let longPress = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        self.tableView.addGestureRecognizer(longPress)

    }
    
    override func viewWillAppear(animated: Bool) {
        tableView.hidden = true
        activityIndicator.startAnimating()
        API.genericYtListPull("top+music")
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
            activityIndicator.stopAnimating()
            
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
        
        if count(self.vidId!) <= 11 {
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
        
        
        // implement alerts
        addTitleToListSheet(vidId!)
        
    }
    
    @IBAction func logOutBtnPressed(sender: AnyObject) {
        
        PFUser.logOut()
        self.tabBarController?.selectedIndex = 0
    }
    
    //MARK: HELPERS
    
    func convertYtApiInfoToCell(notification:NSNotification){
        
        for (key:String, value:JSON) in gJson!["items"] {
           
            let id:String
            if value["id"]["playlistId"] != nil{
                id = value["id"]["playlistId"].stringValue
            }
            else {
               id = value["id"]["videoId"].stringValue
            }
            
            let vidTitle = value["snippet"]["title"].stringValue
            let vidDes = value["snippet"]["description"].stringValue
            let url = value["snippet"]["thumbnails"]["default"]["url"].stringValue
            var vidInfo = VideoItem(vidId: id, vidTitle: vidTitle, vidDesc: vidDes, vidPic: url)
            ytAPILists.append(vidInfo)
        }
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.tableView.reloadData()
        })
        
    }

    //MARK: SearchBar funcs
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        if count(searchText) > 3 {
            let tmp = searchText.stringByReplacingOccurrencesOfString(" ", withString: "+")
            ytAPILists.removeAll(keepCapacity: false)
            API.genericYtListPull(tmp)
        }
    }
    
    //MARK: Alerts
    
    func addTitleToListSheet(vidTitle: String) {
        
        var alertSheet:UIAlertController?
        
        if let objects = gParseList {
            
            alertSheet = UIAlertController(title: vidTitle, message: "Choose list", preferredStyle: UIAlertControllerStyle.ActionSheet)
            
            for x in objects{
                let id = x.objectId
                var myLists:[String] = x["myLists"] as! [String]
                let title:String = x.valueForKey("listTitle") as! String
                let action = UIAlertAction(title: title, style: .Default, handler: { (UIAlertAction) -> Void in
                    
                    myLists.append(self.vidId!)
                    print(myLists)
                    let add = APIRequests()
                    add.addUpdateItemToUserList(id!, newList: myLists)
                    
                    //TODO:Figue out synchronous call before showing alert
                    
                    self.addSingleTitleAlertHelper(true)
                })
                
                alertSheet?.addAction(action)
            }
        }
        else {
            
            alertSheet = UIAlertController(title: vidTitle, message: "Create your first list", preferredStyle: UIAlertControllerStyle.Alert)
            alertSheet?.addTextFieldWithConfigurationHandler({ (text:UITextField!) -> Void in
                
                
                // do something with the code here
            })
            
            let saveAction = UIAlertAction(title: "Save", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                
                
                
            })
            
            alertSheet?.addAction(saveAction)
            
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertSheet?.addAction(cancelAction)
        self.presentViewController(alertSheet!, animated: true, completion: nil)
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
}
