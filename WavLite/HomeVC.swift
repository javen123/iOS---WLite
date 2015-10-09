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

class HomeVC: UIViewController, PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate, LiquidFloatingActionButtonDataSource, LiquidFloatingActionButtonDelegate {
    
   
    @IBOutlet var webView:UIWebView!
    
    //Liquid cells setup
    var cells:[LiquidFloatingCell] = []
    var floatingCell: LiquidFloatingActionButton!
    var floatingBtnImg:UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load webview
        
        let url = NSURL(string: "http://www.wavlite.com/api/videoPlayer.html")
        let request = NSURLRequest(URL: url!)
        
          
        webView.sizeToFit()
        webView.frame.insetInPlace(dx: 8, dy: 8)
        webView.loadRequest(request)
        
        //TODO: Add logout notification
        
        // Liquid floating button add
        setupLiquidTouch()
    }
    
    override func viewWillAppear(animated: Bool) {
        logInHelper()
    }
    
    override func viewDidAppear(animated: Bool) {
        
        logInHelper()
        
    }
    
    
    @IBAction func logoutBtnPressed(sender: AnyObject) {
        PFUser.logOut()
        logInHelper()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Login funcs
    func logInViewController(logInController: PFLogInViewController, didLogInUser user: PFUser) {
        
        curUser = user
        let API = APIRequests()
        API.grabListsFromParse()
       
        
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
    
    func logInViewController(logInController: PFLogInViewController, didFailToLogInWithError error: NSError?) {
        if error != nil {
            print(error?.localizedDescription)
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
        
        print("CurUser is: \(curUser)")
        
        if curUser == nil {
            
            let loginVC = PFLogInViewController()
            
            //clean current lists
            gJson = nil
            gParseList?.removeAll(keepCapacity: true)
            
            loginVC.fields = [PFLogInFields.UsernameAndPassword,
                PFLogInFields.LogInButton,
                PFLogInFields.SignUpButton,
                PFLogInFields.PasswordForgotten,
                PFLogInFields.DismissButton,
//               PFLogInFields.Facebook),
                PFLogInFields.Twitter]
            
            //            loginVC.facebookPermissions = ["public_profile", "email"]
            
            let logoView = UIImageView(image: UIImage(named:"ocLogo50"))
            loginVC.logInView?.logo = logoView
            loginVC.delegate = self
            
            //signup controller
            
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
            let API = APIRequests()
            
            if let inputTitle = aTextField?.text {
                
                API.createListTitle(inputTitle, vidId: nil)
            }
        }
        
        alert.addAction(saveAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }

}
