//
//  APIRequests.swift
//  WavLite
//
//  Created by Jim Aven on 7/29/15.
//  Copyright (c) 2015 Jim Aven. All rights reserved.
//

import Foundation
import Parse
import SwiftyJSON

var gJson:JSON!
var gParseList:[PFObject]!

class APIRequests {
    
   
    let yTMaxResults = 25
    let DEVELOPER_KEY:String = "AIzaSyD9kU-l10psPGVI0ntgVZmpOk6yZnP1urs"
   
    
    func userYTListPull (subject:String) {
        
        // Set up your URL
        let youtubeApi: String = "https://www.googleapis.com/youtube/v3/videos?part=snippet&id=\(subject)&maxResults=\(yTMaxResults)&key=\(DEVELOPER_KEY)"
        var url: NSURL = NSURL(string: youtubeApi)!
        
        // Create your request
        var request: NSURLRequest = NSURLRequest(URL: url)
        
        let queue:NSOperationQueue = NSOperationQueue()
        
        // Send the request asynchronously
        NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler:{ (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
            
            // Callback, parse the data and check for errors
            if data != nil && error == nil {
                gJson = JSON(data:data)
                
                NSNotificationCenter.defaultCenter().postNotificationName("YTFINISHED", object: nil)
                
            } else {
                println("Error: \(error.localizedDescription)")
                
            }
        })
    }
    
    func genericYtListPull (subject:String) {
        
        // have to iterate the string an dmake sure that spaces are joined by a + symbol before proceeding with GET
        
        // Set up your URL
        let youtubeApi: String = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(subject)&maxResults=\(yTMaxResults)&key=\(DEVELOPER_KEY)"

        var url: NSURL = NSURL(string: youtubeApi)!
        
        // Create your request
        var request: NSURLRequest = NSURLRequest(URL: url)
        
        let queue:NSOperationQueue = NSOperationQueue()
        
        // Send the request asynchronously
        NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler:{ (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
            
            // Callback, parse the data and check for errors
            if data != nil && error == nil {
                gJson = JSON(data:data)
                
                NSNotificationCenter.defaultCenter().postNotificationName("ULFINISHED", object: nil)
                
            } else {
                println("Error: \(error.localizedDescription)")
                
            }
        })
    }

     
    func parseLogOut(){
        
        PFUser.logOut()
        
    }
    
    func grabListsFromParse(){
        
        if PFUser.currentUser() != nil {
            
            let query = PFQuery(className: "Lists")
            query.whereKey("createdBy", equalTo: PFUser.currentUser()!)
            query.orderByAscending("myLists")
            
            query.findObjectsInBackgroundWithBlock({ (objects:[AnyObject]?, error:NSError?) -> Void in
                
                if error != nil {
                    println(error?.localizedDescription)
                }
                else {
                    gParseList = objects as? [PFObject]
                }
            })
        }
        else {
            println("user is nil")
            return
        }
    }
}

