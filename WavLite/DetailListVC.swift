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



class DetailListVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    
        
    var videos:PFObject!
    var vidInfo = [VideoItem]()
    var vidIds:String!
   
    
    let API = APIRequests()
    
    
    override func viewWillAppear(animated: Bool) {
        tableView.hidden = true
        activityIndicator.startAnimating()
        API.userYTListPull(vidIds)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "convertYtApiInfoToCell:", name: "YTFINISHED", object: nil)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        convertPFObjectToYouTubeList(videos)
        vidIds = convertPFObjectToYouTubeList(videos)
        self.navigationItem.title = videos["listTitle"] as? String
        
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
       
       
        tableView.hidden = false
        activityIndicator.stopAnimating()
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return vidInfo.count
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let vidId:String = vidInfo[indexPath.row].videoId
        
        let aView = UIView(frame: CGRectMake(10, 150, self.view.frame.width - 10, self.view.frame.width/1.7))
        aView.backgroundColor = UIColor.blackColor()
        
                
        self.view.addSubview(aView)
        
    }
    
    //MARK:Helpers
    
    func convertPFObjectToYouTubeList(object:PFObject) -> String? {
        
        var temp:String!
        
        if let list:[String] = object["myLists"] as? [String]{
            if list.count > 1 {
                temp = ",".join(list)
            }
            else {
                temp = list[0]
            }
        }
        println("temp list is: \(temp)")
        return temp
    }
    
    func convertYtApiInfoToCell(notification:NSNotification){
        
        for (key:String, value:JSON) in gJson["items"] {
            let items = value
            
            let id = items["id"].stringValue
            
            println("Vid id is : \(id)")
            let vidTitle = items["snippet"]["title"].stringValue
            let vidDes = items["snippet"]["description"].stringValue
            let url = items["snippet"]["thumbnails"]["default"]["url"].stringValue
            var vidInfo = VideoItem(vidId: id, vidTitle: vidTitle, vidDesc: vidDes, vidPic: url)
            self.vidInfo.append(vidInfo)
        }

        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.tableView.reloadData()
        })
    }
    
    }
