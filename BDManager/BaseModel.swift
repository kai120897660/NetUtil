//
//  BaseModel.swift
//  family
//
//  Created by APPLE on 2019/8/22.
//  Copyright © 2019 xiaoma. All rights reserved.
//

import UIKit
import HandyJSON

class BaseModel: NSObject, HandyJSON {
    required override init() {}
    
    ///需要保存数据库的模型需要重新此方法
    class func initModel() -> BaseModel {
        let model = BaseModel.init()
        return model
    }
    
    ///数据库表名
    class func tableName() -> String {
        let className = String(NSStringFromClass(self))
        let result  = className.split(separator: ".")
        let tableName = String(result.last!)
        return tableName
    }
    
    ///主键，为空则是自增长的id
    class func primaryKey() -> String? {
        return  nil
    }
    
    ///数据库表名
    func tableName() -> String {
        let tableName = (self.classForCoder as? BaseModel.Type)?.tableName()
        //        let className = String(NSStringFromClass(self.classForCoder))
        //        let result  = className.split(separator: ".")
        //        let tableName = String(result.last!)
        return tableName ?? ""
    }
    
    ///添加到数据库的属性名
    class func DBAllowedPropertyNames() -> Array<String> {
        return []
    }
    
    ///不需要添加到数据库的属性名
    class func DBigonrePropertyNames()  -> Array<String> {
        return []
    }
    
    ///模型转字典
    func ck_keysValues() -> [String: Any] {
        return self.toJSON() ?? [:]
    }
    func ck_keysValuesWithKeys() -> [String]? {
        return nil
    }
    
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
        
    }
    
    override func value(forUndefinedKey key: String) -> Any? {
        return nil
    }
}


///建表操作
extension BaseModel {
    
    ///当前模型的字段和值
    func propertyKeyValues() -> Dictionary<String, Any> {
        
//        let pointer =  UnsafeMutablePointer<_Metadata._ObjcClassWrapper>
        
        
        let modelClass = self.classForCoder as? BaseModel.Type
        
        let igonreArray = modelClass?.DBigonrePropertyNames()
        let allowedArray = modelClass?.DBAllowedPropertyNames()
        var dic = Dictionary<String, Any>()
        let mirror = Mirror.init(reflecting: self)
        for (name, value) in (mirror.children) {
            //            let classStr = NSStringFromClass((value as AnyObject).classForCoder)
            //            if value is Bool {
            //                ck_print("是bool类型")
            //            }
//            ck_print("name = \(name ?? ""), value = \(value ?? "")")
            if (value as? String) == nil && (value as? NSNumber) == nil {
                continue
            }
            
            if (allowedArray?.count)! > 0 {
                
                if (allowedArray?.contains(name!))! {
                    dic[name!] = value
                }
            }else {
                
                if !(igonreArray?.contains(name!))! {
                    dic[name!] = value
                }
            }
            
        }
        return dic
    }
    
    
    //MARK:  --  category func
    ///初始化表
    class func initTable() {
        
        let tableName = self.tableName()
        let properties = self.propertiesName()
        if let olderProperties = UserDefaults.standard.object(forKey: tableName) as? [String: String] {
            ///创建过，如果有字段更新则更新字段
            let allKeys = olderProperties.keys
            for (key, value) in properties {
                if !allKeys.contains(key) {
                    DBManager.standard.addTableParameter(tableName, key: key, type: value)
                }
            }
        }else {///没有创建就创建表
//            DBManager.standard.createTable(self.tableName(), primaryKey: self.primaryKey(), propertiesDic: self.propertiesName())
            UserDefaults.standard.set(properties, forKey: tableName)
            UserDefaults.standard.synchronize()
        }
    }

    
    ///获取模型的属性名和类型
    ///whereDic 数据筛选条件key(字段名)，value(数据库类型)
    class func propertiesName() -> [String: String] {
        
        var outCount: UInt32 = 0
        
        //调用runtime 方法 class_copyPropertyList 获取类的公有属性列表
        let propertyList = class_copyPropertyList(self, &outCount)
        
        var propertiesDic: [String: String] = [:]
        //遍历数组
        for i in 0..<Int(outCount) {
            
            // 取出数组中的元素 objc_property_t?
            let pty = propertyList?[i]
            
            // 获取属性名称 是C字符串 UnsafePointer<Int8>?
            let cName = property_getName(pty!)
            
            //转换成OC String?
            let oName = String(utf8String: cName)
            
            if (self.DBAllowedPropertyNames().count > 0) {
                
                if self.DBAllowedPropertyNames().contains(oName!) {
                    propertiesDic[oName!] = self.propertyType(pty!)
                }
            }else {
                if !self.DBigonrePropertyNames().contains(oName!) {
                    propertiesDic[oName!] = self.propertyType(pty!)
                }
            }
            
            
        }
        free(propertyList)
        
        return propertiesDic
    }
    
    ///存入数据库的类型
    class func propertyType(_ pty: objc_property_t) -> String {
        let attribuesStr = NSString.init(cString: property_getAttributes(pty)!, encoding: String.Encoding.utf8.rawValue)
        if (attribuesStr?.hasPrefix("T@\"NSNumber\""))! {
            return "TINYINT"//(attribuesStr?.substring(with: NSRange.init(location: 3, length: (attribuesStr?.range(of: ",").location)! - 4)))!
        }else if (attribuesStr?.hasPrefix("Ti"))! ||
            (attribuesStr?.hasPrefix("Tq"))! ||
            (attribuesStr?.hasPrefix("TQ"))! {
            return "BIGINT"
        }else if (attribuesStr?.hasPrefix("Tl"))! ||
            (attribuesStr?.hasPrefix("Tc"))! ||
            (attribuesStr?.hasPrefix("Ts"))! {
            return "INTEGER"
        }else if (attribuesStr?.hasPrefix("Tf"))! ||
            (attribuesStr?.hasPrefix("Td"))! {
            return "DECIMAL"
        }else if (attribuesStr?.hasPrefix("Tb"))! {
            return "TINYINT"
        }else {
            return "TEXT"
        }
    }
}


struct Person {
    var isBoy: Bool = true
    var age: Int = 0
    var height: Double = 130.1
    var name: String = "jack"
}


/**
//MARK:     ---     数据库增删改查
extension BaseModel {
    
    func synchronizeDB(_ whereDic: [String: Any]?) {
        var dic = whereDic
        if whereDic == nil {
            let modelClass = self.classForCoder as! BaseModel.Type
            let key = modelClass.primaryKey() == nil ? "id" : modelClass.primaryKey()
            dic = [key!: self.propertyKeyValues()[key!] as! String]
        }
        let result = DBManager.standard.selectDB(searchDic: dic, className: self.classForCoder as! BaseModel.Type, order: nil,  isOr: false)
        if result.isEmpty {
            self.insertIntoDB()
            
        }else {
            self.updateDB(dic)
        }
    }
    
    ///插入一条数据到数据库
    func insertIntoDB() {
        let dic = self.propertyKeyValues()
        DBManager.standard.insertDB(tableName: self.tableName(), dic: dic)
    }
    
    ///更新某条数据
    ///whereDic 数据筛选条件key(字段名)，value(字段值)
    func updateDB(_ whereDic: [String: Any]?) {
        let modelClass = self.classForCoder as? BaseModel.Type
        let key = modelClass?.primaryKey()
        var dic = whereDic
        if dic == nil {
            dic = [key!: self.propertyKeyValues()[key!] as! String]
        }
        let params = self.propertyKeyValues().filter {
            return !(dic?.keys.contains($0.key))!
        }
        DBManager.standard.updateDB(tableName: self.tableName(), dic: params, whereDic: dic)
        
    }
    
    ///删除某条数据
    ///whereDic 数据筛选条件key(字段名)，value(字段值)
    func deleteDB(_ whereDic: [String: Any]?, finished: Completed?) {
        let modelClass = self.classForCoder as? BaseModel.Type
        let key = modelClass?.primaryKey()
        var dic = whereDic
        if dic == nil {
            dic = [key!: self.propertyKeyValues()[key!] as! String]
        }
        DBManager.standard.deleteDB(tableName: self.tableName(), whereDic: dic, completed: finished)
    }

    
    ///whereDic 模糊查询key(字段名)，value(字段值)
    class func selectModelLike(_ whereDic: [String: Any]?, order: String?) -> [Any] {
        var sql = "SELECT * FROM " + self.tableName()
        var index = 0
        if whereDic != nil {
            for (key, value) in whereDic! {
                if index == 0 {
                    sql = sql + " WHERE "  + key + " like '%%\(value)%%' "
                }else {
                    sql = sql + " OR " + key + " like '%%\(value)%%' "
                }
                index += 1
            }
        }
        if order != nil {
            sql += "order by \(order!) desc"
        }
        let rs = self.selectModel(sql)
        return rs
        
    }
    
    ///whereDic 数据筛选条件key(字段名)，value(字段值)
    class func selectModel(_ whereDic: [String: Any]?) -> [Any] {
//        let mirror = Mirror.init(reflecting: self)
//
//        let type =  mirror.subjectType //as! AnyClass
//        let model = type.init()
        return self.selectModel(whereDic, order: nil, isOr: false)
    }
    
    class func selectModel(_ whereDic: [String: Any]?, isOr: Bool) -> [Any] {
        return self.selectModel(whereDic, order: nil, isOr: isOr)
    }
    ///查询按某个字段排序（默认降序）
    class func selectModel(_ whereDic: [String: Any]?, order: String?) -> [Any] {
        return self.selectModel(whereDic, order: order, isOr: false)
        
    }
    
    class func selectModel(_ whereDic: [String: Any]?, order: String?, isOr: Bool) -> [Any] {
        let rs = DBManager.standard.selectDB(searchDic: whereDic, className: self, order: order, isOr: isOr)
        return rs
        
    }
    
    ///查询当前表的数据
    class func selectModel(_ sql: String) -> [Any] {
        let rs = DBManager.standard.selectDB(sql, className: self)
        
        return rs
        
    }
    
    ///批量同步数据库数据
    ///modelArray     模型数组
    class func synchronizeDB(_ modelArray: [Any]) {
        for item in modelArray {
            let model = item as? BaseModel
            model?.synchronizeDB(nil)
            //            let key = self.primaryKey() == nil ? "id" : self.primaryKey()
            //            model?.synchronizeDB([key!: model?.propertyKeyValues()[key!] as! String])
        }
    }
    
    ///批量删除某条数据
    ///whereDic 数据筛选条件key(字段名)，value(字段值)
    class func deleteDB(_ modelArray: [Any], finished: Completed?) {
        var index = 0
        for item in modelArray {
            let model = item as? BaseModel
            model?.deleteDB(nil, finished: {
                index += 1
                if index == modelArray.count {
                    finished?()
                }
            })
        }
    }
    
    ///删除某条数据
    ///whereDic 数据筛选条件key(字段名)，value(字段值)
    class func deleteDB(_ whereDic: [String: Any]?, finished: Completed?) {
        
        DBManager.standard.deleteDB(tableName: self.tableName(), whereDic: whereDic, completed: finished)
    }
    
    
    ///清空表数据
    class func clearTable(_ finished: Completed?) {
        DBManager.standard.deleteDB(tableName: self.tableName(), whereDic: nil, completed: finished)
    }

}
*/
