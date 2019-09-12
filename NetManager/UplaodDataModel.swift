//
//  uplaodData.swift
//  net
//
//  Created by 陈凯文 on 2019/9/12.
//  Copyright © 2019 陈凯文. All rights reserved.
//

import UIKit


public class UplaodDataModel {
    
    ///图片名称
    public var name : String = "file"
    ///图片数据
    public var data : Data?
    ///文件名称
    public var fileName = ""
    ///图片类型(""为不指定类型)
    public var mineType = "image/png"
    
    init(data: Data?, fileName: String, mineType: String) {
//        super.init()
        self.fileName = fileName
        self.data = data
        self.mineType = mineType
    }
    
//    required init() {
//        fatalError("init() has not been implemented")
//    }
}
