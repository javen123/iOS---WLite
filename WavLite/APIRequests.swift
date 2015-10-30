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

    func grabListsFromParse(completed:UpdateComplete){
        
        if curUser != nil {
            
            userLists.removeAll()
            gParseList = nil
            
            let query = PFQuery(className: "Lists")
            query.whereKey("createdBy", equalTo: curUser!)
            query.orderByAscending("listTitle")
            query.findObjectsInBackgroundWithBlock({
                
                objects, error in
            
                if error != nil {
                    print(error!.localizedDescription)
                }
                else {
                    gParseList = objects! as [PFObject]
                   
                    for x in objects! {
                        
                        if let title = x["listTitle"] {
                            let tmpTitle = title as! String
                            
                            var tmp = [String]()
                            if let lists = x["myLists"] as? [String] {
                                for y in lists {
                                    tmp.append(y)
                                }
                            }
                            
                            let list = MyLists(title: tmpTitle, lists: tmp)
                            userLists.append(list)
                            
                        }
                    }
                    completed()
                }
            })
        }
        else {
            print("user is nil")
            return
        }
    }

    
    func addUpdateItemToUserList(listId:String, newList:[String], completed:UpdateComplete) {
        
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
                            
                            self.grabListsFromParse({ () -> () in
                                return
                            })
                            completed()
                        }
                    })
                }
            }
            else {
                
                
                print("Object is nil")
                
            }
        })
    }
    
    func removeUserList(name:[String]) {
        
        var pfList:[PFObject]!
        
        for x in name {
            let tmp = gParseList!.filter({$0["listTitle"] as! String == x})
            pfList = tmp
        }
        
        PFObject.deleteAllInBackground(pfList) {
            
            success, err in
            
            if err != nil {
                print(err?.localizedDescription)
            } else {
                print("Success")
            }
        }
    }
    
    func createListTitle(listTitle:String, vidId:[String]?, completed:UpdateComplete) {
        
        //create list object
        
        let newList = PFObject(className:"Lists")
        newList["listTitle"] = listTitle
        if let newId = vidId {
            newList["myLists"] = newId
        }
        
        // create relation for list to use
        
        let relation = newList.relationForKey("createdBy")
        relation.addObject(curUser!)
        
        newList.saveInBackgroundWithBlock {
            
            success, error in
            if error != nil {
                print(error?.localizedDescription)
                
            }
            else if success == false {
                print("something went wrong with Parse")
                
            }
            else {
                self.grabListsFromParse({ () -> () in
                    completed()
                })
                
            }
        }
    }
    
    func updateUserListsToParse(mylists:[PFObject]){
        
    }
    
    func convertUserListsToParseObjectsAndSaveToParse() {
        
        var parseObjects = [PFObject]()
        
        if userLists.count > 0 && gParseList != nil{
            
            for x in userLists {
                
                let tmp = gParseList!.filter({$0["listTitle"] as! String == x.title})
                let id = tmp[0].valueForKey("objectId") as? String
                print(tmp)
                let object = PFObject(withoutDataWithClassName: "Lists", objectId: id)
                object.setObject(x.title, forKey: "listTitle")
                object.setObject(x.lists, forKey: "myLists")
                parseObjects.append(object)
            }
            
            
            PFObject.saveAllInBackground(parseObjects, block: {
                success, err in
                
                if err != nil {
                    print(err?.debugDescription)
                } else if success == true {
                    print("PARSE SUCCESS")
                    self.grabListsFromParse({ () -> () in
                        return
                    })
                } else {
                    print("SHIT..PARSE!!!")
                }
            })
            changesMade = false
        }
        
    }

}