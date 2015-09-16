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


class SearchViewVC: UIViewController,UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate  {
    
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var playerView: YouTubePlayerView!
    
    
   
    var ytAPILists:[VideoItem] = [VideoItem]()
    var playerActive = false
    
    let API = APIRequests()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // searchbar setup
        
        searchBar.placeholder = "Enter your search here"
        
        // youtube player set up
        
        self.playerView.hidden = true
        
        
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
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        self.playerActive = true
        
        let vidId = ytAPILists[indexPath.row].videoId
        
        if count(vidId) <= 11 {
            self.playerView.loadVideoID(vidId)
            
        }
        else {
            self.playerView.loadPlaylistID(vidId)
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
    
    //MARK: HELPERS
    
    func convertYtApiInfoToCell(notification:NSNotification){
        
        for (key:String, value:JSON) in gJson["items"] {
           
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
    
}
