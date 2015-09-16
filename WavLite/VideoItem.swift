//
//  VideoItem.swift
//  WavLite
//
//  Created by Jim Aven on 8/3/15.
//  Copyright (c) 2015 Jim Aven. All rights reserved.
//

import Foundation

struct VideoItem {
    
    var videoId:String
    var videoTitle:String
    var videoDescription:String
    var picURL:String
    
    init (vidId:String, vidTitle:String, vidDesc:String, vidPic:String){
        videoId = vidId
        videoTitle = vidTitle
        videoDescription = vidDesc
        picURL = vidPic
    }
}
