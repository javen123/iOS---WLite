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

//Globals

var gJson:JSON?
var gParseList:[PFObject]?
var curUser:PFUser?

class APIRequests {
    
   
    let yTMaxResults = 25
    let DEVELOPER_KEY:String = "AIzaSyD9kU-l10psPGVI0ntgVZmpOk6yZnP1urs"
    
    func userYTListPull (subject:String) {
        
        // Set up your URL
        let youtubeApi: String = "https://www.googleapis.com/youtube/v3/videos?part=snippet&id=\(subject)&&fields=items(id%2Csnippet)&key=\(DEVELOPER_KEY)"  
        let url:NSURL = NSURL(string: youtubeApi)!
        
        // Create your request
        let request: NSURLRequest = NSURLRequest(URL: url)
        
        let queue:NSOperationQueue = NSOperationQueue()
        
        // Send the request asynchronously
        NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler:{ (response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
            
            // Callback, parse the data and check for errors
            if data != nil && error == nil {
                gJson = JSON(data:data!)
                
                NSNotificationCenter.defaultCenter().postNotificationName("YTFINISHED", object: nil)
                
            } else {
                print("Error: \(error!.localizedDescription)")
                
            }
        })
    }
    
    func genericYtListPull (subject:String) {
        
        // have to iterate the string an dmake sure that spaces are joined by a + symbol before proceeding with GET
        
        // Set up your URL
        let youtubeApi: String = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(subject)&maxResults=\(yTMaxResults)&key=\(DEVELOPER_KEY)"

        let url: NSURL = NSURL(string: youtubeApi)!
        
        // Create your request
        let request:NSURLRequest = NSURLRequest(URL: url)
        
        let queue:NSOperationQueue = NSOperationQueue()
        
        // Send the request asynchronously
        NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler:{ (response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
            
            // Callback, parse the data and check for errors
            if data != nil && error == nil {
                gJson = JSON(data:data!)
                
                NSNotificationCenter.defaultCenter().postNotificationName("ULFINISHED", object: nil)
                
            } else {
                print("Error: \(error!.localizedDescription)")
                
            }
        })
    }

    func grabListsFromParse(){
        
        if curUser != nil {
            
            gParseList = nil
            
            let query = PFQuery(className: "Lists")
            query.whereKey("createdBy", equalTo: curUser!)
            query.orderByAscending("myLists")
            query.findObjectsInBackgroundWithBlock({
                
                objects, error in
            
                if error != nil {
                    print(error!.localizedDescription)
                }
                else {
                    gParseList = objects! as [PFObject]
                    print("Parse info: \(gParseList)")
                }
            })
        }
        else {
            print("user is nil")
            return
        }
    }

    
    func addUpdateItemToUserList(listId:String, newList:[String]) {
        
        let query = PFQuery(className: "Lists")
        query.getObjectInBackgroundWithId(listId, block: {
            
            object, error in
            
            if error != nil {
                print(error?.localizedDescription)
               
            }
            else if object != nil{
                
                if let list = object {
                    list["myLists"] = newList as AnyObject
                    list.saveInBackgroundWithBlock({
                        
                        success, error in
                        if error != nil {
                            print(error!.localizedDescription)
                        }
                        else {
                            self.grabListsFromParse()
                        }
                    })
                }
            }
            else {
                print("Object is nil")
                
            }
        })
    }
    
    func removeUserList(listId:String) {
        
        let query = PFQuery(className: "Lists")
        query.getObjectInBackgroundWithId(listId, block: {
        object, error in
        
            if error != nil {
                //do some alert here
            }
            
            else if let x = object{
                
                x.deleteInBackgroundWithBlock(){
                    success, error in
                    if error != nil {
                        //alert box here
                    }
                    else if success {
                        self.grabListsFromParse()
                    }
                }
            }
        })
    }
    
    func createListTitle(listTitle:String, vidId:[String]?) {
        
        //create list object
        
        let newList = PFObject(className:"Lists")
        newList["listTitle"] = listTitle
        if let newId = vidId {
            newList["myLists"] = newId
        }
        
        // create relation for list to use
        
        let relation = newList.relationForKey("createdBy")
        relation.addObject(curUser!)
        
        newList.saveEventually {
            
            success, error in
            if error != nil {
                print(error?.localizedDescription)
                
            }
            else if success == false {
                print("something went wrong with Parse")
                
            }
            else {
                self.grabListsFromParse()
                
            }
        }
    }
    
}