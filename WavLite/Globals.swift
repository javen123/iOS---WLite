//
//  Globals.swift
//  WavLite
//
//  Created by Jim Aven on 10/29/15.
//  Copyright © 2015 Jim Aven. All rights reserved.
//

import Foundation
import SwiftyJSON



var gJson:JSON?
var gParseList:[PFObject]?
var userLists = [MyLists]()
var changesMade = false

let BACKGROUND_COLOR = UIColor(red: 18 / 225.0, green: 32 / 225.0, blue: 64 / 225.0, alpha: 1.0)


public typealias UpdateComplete = () -> ()
public typealias AlertOrder = () -> ()

var FACEBOOK_APP_ID = "1620572828207555"