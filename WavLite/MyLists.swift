//
//  MyLists.swift
//  WavLite
//
//  Created by Jim Aven on 10/29/15.
//  Copyright © 2015 Jim Aven. All rights reserved.
//

import Foundation

class MyLists {
    
    private var _title:String!
    private var _lists = [String]()
    
    var title:String {
        return _title
    }
    
    var lists:[String] {
        return _lists
    }
    
    
    init(title:String, lists:[String]){
        self._title = title
        self._lists = lists
    }
    
    func addNewTitle(vidId:String){
        self._lists.append(vidId)
    }
    
    func removeVideoAtIndex(index:Int) {
        _lists.removeAtIndex(index)
    }
    
        
}