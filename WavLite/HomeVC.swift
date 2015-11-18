//
//  HomeVC.swift
//  WavLite
//
//  Created by Jim Aven on 7/28/15.
//  Copyright (c) 2015 Jim Aven. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import SwiftyJSON
import WebKit

class HomeVC: UIViewController, PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate, LiquidFloatingActionButtonDataSource, LiquidFloatingActionButtonDelegate {
    
   
   
    @IBOutlet weak var webView: UIWebView!
   
    
    //Liquid cells setup
    
    var cells:[LiquidFloatingCell] = []
    var floatingCell: LiquidFloatingActionButton!
    var floatingBtnImg:UIImage!
    
    var signedIn:Bool {
        let defs = NSUserDefaults.standardUserDefaults().boolForKey("SIGNEDIN")
        return defs
    }
    
    let reachability = Reachability.reachabilityForInternetConnection()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //check internet connection
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "noConnection:", name: ReachabilityChangedNotification, object: reachability)
        
        // Load webview
        
        webView.sizeToFit()
        webView.frame.insetInPlace(dx: 8, dy: 8)
        
        let url = NSURL(string: "http://www.wavlite.com/api/videoPlayer.html")
        let request = NSURLRequest(URL: url!)
        self.webView.loadRequest(request)
        
        // Liquid floating button add
        
        setupLiquidTouch()
    }
    
    func noConnection(note:NSNotification){
        
        let curReach = note.object as! Reachability
        if curReach.isReachable() == false {
            let alert = UIAlertController(title: "Oops", message: "you need an internet connection to properly use this app", preferredStyle: .Alert)
                self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        logInHelper()
    }
    
    override func viewDidAppear(animated: Bool) {
        
        logInHelper()
        
    }
    
    
   
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Login funcs
    func logInViewController(logInController: PFLogInViewController, didLogInUser user: PFUser) {
        
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "SIGNEDIN")
        
        let API = APIRequests()
        API.grabListsFromParse { () -> () in
            return
        }
        
       //        let graphRequest:FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "/me?fields=picture,first_name,last_name,email", parameters: nil)
        //        graphRequest.startWithCompletionHandler({
        //            connection, result, error in
        //
        //            if error != nil {
        //                println(error.localizedDescription)
        //            }
        //            else {
        //                // assign fb
        //
        //                user["firstName"] = result!["first_name"]
        //                user["lastName"] = result!["last_name"]
        //
        //                user.email = (result!["email"] as! String)
        //
        //                let pictureURL:String = ((result["picture"] as! NSDictionary) ["data"] as! NSDictionary) ["url"] as! String
        //                let url = NSURL(string: pictureURL)
        //                let request = NSURLRequest(URL: url!)
        //
        //                NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {
        //                    response, data, error in
        //                    if error != nil {
        //                        println(error.localizedDescription)
        //                    }
        //                    else if data != nil {
        //                        let imageFile = PFFile(name: "avatar.jpg", data: data)
        //                        user["picture"] = imageFile
        //                        user.saveInBackgroundWithBlock{
        //                            success, error in
        //                            if success == true {
        //                                fetchUserOwnerPlaces()
        //                            }
        //                        }
        //                    }
        //                })
        //
        //            }
        //        })
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func btngenrePressed(sender: UIButton) {
        
        // 0 rock 1 jazz 2 hip 3 country blues 4 r&b 5
        var key:String!
        
        switch sender.tag {
        case 0:
           key = "top+rock+hits"
        case 1:
            key = "top+jazz+hits"
        case 2:
            key = "top+hip+hop+hits"
        case 3:
            key = "top+country+hits"
        case 4:
            key = "top+blues+hits"
        default:
            key = "top+r&b+hits"
        }
        
        let prefs = NSUserDefaults.standardUserDefaults()
        prefs.setValue(key, forKeyPath: "GENREKEY")
        
        self.performSegueWithIdentifier("searchSegue", sender: self)
        
    }
    
    func logInViewController(logInController: PFLogInViewController, didFailToLogInWithError error: NSError?) {
        if error != nil {
            let alert = UIAlertController(title: "Oops", message: "Something went wrong please try again", preferredStyle: .Alert)
            self.presentViewController(alert, animated: true, completion: nil)
        }
        else {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func signUpViewController(signUpController: PFSignUpViewController, shouldBeginSignUp info: [NSObject : AnyObject]) -> Bool {
        return true
    }
    
    func signUpViewController(signUpController: PFSignUpViewController, didSignUpUser user: PFUser) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
        
    func logInHelper(){
        
        
        if !self.signedIn {
            
            let loginVC = PFLogInViewController()
            
            //clean current lists
            gJson = nil
            gParseList?.removeAll(keepCapacity: true)
            
            loginVC.fields = [PFLogInFields.UsernameAndPassword,
               
                PFLogInFields.LogInButton,
                PFLogInFields.SignUpButton,
                PFLogInFields.PasswordForgotten,
                PFLogInFields.DismissButton,
                PFLogInFields.Facebook,
                PFLogInFields.Twitter]
            
            loginVC.facebookPermissions = ["public_profile", "email"]
            
            loginVC.view.backgroundColor = BACKGROUND_COLOR
            let logoView = UIImageView(image: UIImage(named:"ic_launcher_192"))
            logoView.contentMode = UIViewContentMode.ScaleAspectFit
            loginVC.logInView?.logo = logoView
            loginVC.delegate = self
            
            //signup controller
            
            loginVC.signUpController?.view.backgroundColor = BACKGROUND_COLOR
            loginVC.signUpController?.fields = ([PFSignUpFields.UsernameAndPassword, PFSignUpFields.Email])
            loginVC.signUpController?.signUpView?.logo = logoView
            loginVC.signUpController?.delegate = self
            
            
            self.presentViewController(loginVC, animated: true, completion: nil)
        }
        else {
            
            return
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
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: "SIGNEDIN")
            logInHelper()
            
        }
        else if index == 1 {
            story = "searchVC"
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
        let toSearchCell = LiquidFloatingCell(icon: UIImage(named: "btn_search.png")!)
        let logoutCell = LiquidFloatingCell(icon: UIImage(named: "btn_logout.png")!)
        
        self.cells.append(logoutCell)
        self.cells.append(toSearchCell)
        self.cells.append(toListsCell)
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

}
