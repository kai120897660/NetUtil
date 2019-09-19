//
//  DBManager.swift
//  family
//
//  Created by APPLE on 2019/8/22.
//  Copyright © 2019 xiaoma. All rights reserved.
//

import UIKit

typealias Completed = () -> Void

class DBManager {
    
    ///1、需要创建数据库或更新字段的模型名称需要继承BaseModel,并把对应的模型类名在DBModel.plist文件中
    ///2、key为当前数据版本，value为该版本需要升级和修改的表对应Model的类名
    ///3、把info.plist中DBVersion字段+1

    ///single
    static let standard = DBManager()

    var dbQueue : FMDatabaseQueue!
    
    private let dbVersionKey = "dbVersionKey"
    
    private init() {
        self.dbQueue = FMDatabaseQueue(path: PathUtil.DBPath())
        self.dbQueue.inDatabase { (db) in
            db.open()
//            do {
//                try db.executeUpdate("PRAGMA foreign_keys=ON;", values: nil)
//                ck_print("外键支持打开")
//            }catch let error {
//                ck_print(error.localizedDescription)
//            }
        }
    }
    
    ///初始化数据库表
    func updateDB() {
        let dbVersion = (Bundle.main.infoDictionary!["DBVersion"] as! NSNumber).intValue
        let olderVersion = UserDefaults.standard.integer(forKey: self.dbVersionKey)
        ///判断当前数据库 是否 需要升级
        if dbVersion > olderVersion {
            let path = Bundle.main.path(forResource: "DBModel", ofType: "plist")
            let classDic = NSDictionary.init(contentsOfFile: path!)
            let keyArray = classDic?.allKeys.sorted(by: { (obj1, obj2) -> Bool in
                if Int(obj1 as! String)! > Int(obj2 as! String)! {
                    return false
                }
                return true
            })
            for item in keyArray! {
                let key = item as! String
                if Int(key)! > olderVersion {
                    let classArray = classDic![key] as! [String]
                    for name in classArray {
                        //动态获取命名空间
                        let namespace = Bundle.main.infoDictionary!["CFBundleExecutable"] as! String
                        //注意工程中必须有相关的类，否则程序会crash
                        let className : AnyClass? = NSClassFromString(namespace + "." + name)
                        let classType = className as? BaseModel.Type
                        classType?.initTable()
                        
                        ck_print(className)
                    }
                }
            }
            UserDefaults.standard.set(dbVersion, forKey: self.dbVersionKey)
            UserDefaults.standard.synchronize()
        }
        
    }

    
    
    func opreateDB(_ sql: String, _ values: [Any]?, completed: Completed?) {
        self.dbQueue.inDatabase { (db) in
            do{
                try db.executeUpdate(sql, values: values)
                ck_print("数据库操作成功")
                completed?()
            }catch{
                ck_print(db.lastErrorMessage())
            }
        }
    }
    
    ///创建新表
    ///properties该表需要创建的字段
    func createTable(_ tableName: String, primaryKey: String?, properties: [PropertyModel]) {
        var  sql = "CREATE TABLE IF NOT EXISTS " + tableName + "(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
        if primaryKey != nil{
            sql =  "CREATE TABLE IF NOT EXISTS " + tableName + "(\(primaryKey!) TEXT PRIMARY KEY NOT NULL, "
        }
        
        var index = 0
        for property in properties {
            sql += property.name + " " + property.DBType
            if index == properties.count - 1 {
                sql += ")"
            }else {
                sql += ", "
            }
            
            index += 1
        }
        self.opreateDB(sql, nil, completed: nil)
    }
    
    ///insert Into table with key-value
    func insertDB(_ tableName: String, propeties: [PropertyModel]) {
        var valueArray = Array<Any>()
        var sqlUpdatefirst = "INSERT INTO '" + tableName + "' ("
        var sqlUpdateLast = " VALUES("
        var index = 0
        for propety in propeties {
            if index != propeties.count - 1 {
                sqlUpdatefirst = sqlUpdatefirst + propety.name + ","
                sqlUpdateLast = sqlUpdateLast + "?,"
            }else{
                sqlUpdatefirst = sqlUpdatefirst + propety.name + ")"
                sqlUpdateLast = sqlUpdateLast + "?)"
            }
            valueArray.append(propety.value as Any)
            index += 1
        }
        self.opreateDB(sqlUpdatefirst + sqlUpdateLast, valueArray, completed: nil)
    }
    
    ///update to table with key-value where parameter
    func updateDB(_ tableName: String, propetise: [PropertyModel], whereDic: [String: Any]?) {
        var valueArray = Array<Any>()
        var sqlUpdate  = "UPDATE " + tableName +  " SET "
        var index = 0
        for proprty in propetise {
            if index != propetise.count - 1 {
                sqlUpdate = sqlUpdate + proprty.name + " = ?,"
            }else {
                sqlUpdate = sqlUpdate + proprty.name + " = ?"
            }
            valueArray.append(proprty.value as Any)
            index += 1
        }
        index = 0
        if whereDic != nil {
            for (key, value) in whereDic! {
                if index == 0 {
                    sqlUpdate = sqlUpdate + " WHERE "  + key + " = ? "
                }else {
                    sqlUpdate = sqlUpdate + " AND " + key + " = ?"
                }
                valueArray.append(value)
                index += 1
            }
        }
        self.opreateDB(sqlUpdate, valueArray, completed: nil)
    }
    
    func selectDB(_ whereDic: [String: Any]?, type: CKDBManager.Type, order: String?, isOr: Bool) -> [Any] {
        var sql = "SELECT * FROM " + type.ck_tableName()
        var index = 0
        if let whereDic = whereDic {
            for (key, value) in whereDic {
                if index == 0 {
                    sql = sql + " WHERE "  + key + " = '\(value)' "
                }else {
                    sql = sql + (isOr == true ? " OR " : " AND ") + key + " = '\(value)' "
                }
                index += 1
            }
        }
        if order != nil {
            sql += "order by \(order!) desc"
        }
        return selectDB(sql, type: type)
    }
    
    func selectDB(_ sql: String, type: CKDBManager.Type) -> [Any] {
        
        var resultArray: [Any] = []
        self.dbQueue.inDatabase { (db) in
            do{
                let rs = try db.executeQuery(sql, values: nil)
                let properties = type.properties
                while rs.next() {
                    var dic: [String: Any] = [:]
                    for propety in properties! {
                        if propety.DBType == "TINYINT" {
                            let value = rs.bool(forColumn: propety.name)
                            dic[propety.name] = value
                            //                            model.setValue(NSNumber.init(value: modelValue), forKey: propety.name)
                        }else if propety.DBType == "DECIMAL" {
                            let modelValue = rs.double(forColumn: propety.name)
                            dic[propety.name] = modelValue
                        }else if propety.DBType == "INTEGER" {
                            let modelValue = rs.int(forColumn: propety.name)
                            dic[propety.name] = modelValue
                        }else if propety.DBType == "BIGINT" {
                            let modelValue = rs.longLongInt(forColumn: propety.name)
                            dic[propety.name] = modelValue
                        }else {
                            let modelValue = rs.string(forColumn: propety.name)
                            dic[propety.name] = modelValue
                        }
                    }
                    resultArray.append(dic)
                }
                rs.close()
            }catch{
                ck_print(db.lastErrorMessage())
            }
        }
        return resultArray
    }
    
    private func setResult(_ className: BaseModel.Type, _ rs: FMResultSet) -> [Any] {
        let keyValues = className.propertiesName()
        var resultArray: [Any] = []
        while rs.next() {
            let model = className.initModel()
            for (key, value) in keyValues {
                if value == "TINYINT" {
                    let modelValue = rs.bool(forColumn: key)
                    model.setValue(NSNumber.init(value: modelValue), forKey: key)
                }else if value == "DECIMAL" {
                    let modelValue = rs.double(forColumn: key)
                    model.setValue(modelValue, forKey: key)
                }else if value == "INTEGER" {
                    let modelValue = rs.int(forColumn: key)
                    model.setValue(modelValue, forKey: key)
                }else if value == "BIGINT" {
                    let modelValue = rs.longLongInt(forColumn: key)
                    model.setValue(modelValue, forKey: key)
                }else {
                    let modelValue = rs.string(forColumn: key)
                    model.setValue(modelValue, forKey: key)
                }
            }
            resultArray.append(model)
        }
        return resultArray
    }

    ///delete parameter from table where parameter
    func deleteDB(_ tableName: String, whereDic: [String: Any]?, completed: Completed?) {
        let queue = DispatchQueue.init(label: "deleteTable")
        queue.async {
            var sql = "DELETE FROM " + tableName
            var index = 0
            var valueArray = Array<Any>()
            if whereDic != nil {
                for (key, value) in whereDic! {
                    if index == 0 {
                        sql = sql + " WHERE "  + key + " = ?"
                    }else {
                        sql = sql + "AND" + key + " = ?"
                    }
                    valueArray.append(value)
                    index += 1
                }
            }
            self.opreateDB(sql, valueArray, completed: completed)
        }
    }
    ///delete table
    func deleteTable(_ tableName: String) {
        let  sql = "DROP TABLE " + tableName
        self.opreateDB(sql, nil, completed: nil)
        
    }
    ///add parameter into table
    func addTableParameter(_ tableName: String, key: String, type: String?) {
        var sql  = "ALTER TABLE " + tableName + " ADD COLUMN " + key + " varchar(256)"
        if type != nil {
            sql = "ALTER TABLE " + tableName + " ADD COLUMN " + key + " \(type!)"
        }
        self.opreateDB(sql, nil, completed: nil)
    }
}

