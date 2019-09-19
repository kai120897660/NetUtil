//
//  PathUtil.swift
//  family
//
//  Created by APPLE on 2019/8/22.
//  Copyright © 2019 xiaoma. All rights reserved.
//


import UIKit

let DBFileName = "DB"
let AudioRecorderName = "/tempAudioRecordr"

class PathUtil: NSObject {
    
    ///documents path
    class func  DocumentsPath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsPath = paths[0]
        return documentsPath
    }
    ///caches Path
    class func  CachesPath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsPath = paths[0]
        return documentsPath
    }
    
    ///caches Path
    class func  DBPath() -> String {
        let path = "\(self.DocumentsPath())/\(DBFileName)"
        print("\(path)")
        return path
    }
    
    ///caches Path
    class func  audioRecordePath() -> String {
        let path = self.DocumentsPath() + AudioRecorderName
//        if FileManager.default.fileExists(atPath: path) {
//            FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
//        }
        
        return path
    }
    
}
