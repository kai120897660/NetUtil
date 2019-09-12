//
//  ResultModel.swift
//  net
//
//  Created by 陈凯文 on 2019/9/12.
//  Copyright © 2019 陈凯文. All rights reserved.
//

import UIKit
import HandyJSON

public struct ResultModel: HandyJSON {
    
    public init() {
        
    }
    
    public var code: Int!
    public var data: Any!
    public var message: String!
}
