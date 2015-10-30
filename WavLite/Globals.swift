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
var curUser:PFUser?
var userLists = [MyLists]()
var changesMade = false

public typealias UpdateComplete = () -> ()
public typealias AlertOrder = () -> ()