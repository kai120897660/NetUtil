//
//  TestModel.swift
//  net
//
//  Created by 陈凯文 on 2019/9/16.
//  Copyright © 2019 陈凯文. All rights reserved.
//

import UIKit

struct TestModel: CKDBManager {
    
    var name: String!
    
    var age: String!
    
//    var brithday: [String]!
    
    static func getClass() {
        let mirror = Mirror.init(reflecting: self)
        let type = mirror.subjectType
        ck_print(type)
    }
    
    func getClass() {
        let mirror = Mirror.init(reflecting: self)
        let type = mirror.subjectType
        ck_print(type)
        
    }
    
    static func ck_tableName() -> String {
      return "Test"
    }
    
//    static func ck_ignoresProperties() -> [String]? {
//        return ["brithday"]
//    }
}
