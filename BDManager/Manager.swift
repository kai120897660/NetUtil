//
//  Manager.swift
//  net
//
//  Created by 陈凯文 on 2019/9/17.
//  Copyright © 2019 陈凯文. All rights reserved.
//

import UIKit


public protocol CKDBManager: CKModelOpreate {
    ///返回自定义表名
    static func ck_tableName() -> String
    ///默认id自动增长，重写返回自定义主键
    static func ck_primarykey() -> String?
}

extension CKDBManager {
    
    public static func ck_initTable() {
        DBManager.standard.createTable(self.ck_tableName(), primaryKey: self.ck_primarykey(), properties: self.properties!)
    }
    
    ///数据库表主键
    static func ck_primarykey() -> String? {
        return nil
    }
    
}

public extension CKDBManager {
    
    typealias Completed = () -> Void
    
    ///插入一条数据到数据库
    func insertIntoDB() {
        DBManager.standard.insertDB(Self.ck_tableName(), propeties: self.propertyKeyValues())
        
    }
    
    func synchronizeDB(_ whereDic: [String: Any]?) {
        var dic = whereDic
        if whereDic == nil {
            let primaryKey = Self.ck_primarykey()
            let key = primaryKey ?? "id"
            dic = [key: self.propertyKeyValues().filter({ $0.name == key }).first?.value as Any]
        }
        Self.selectModel(dic).isEmpty ? self.insertIntoDB() : self.updateDB(dic)
    }
    
    ///更新某条数据
    ///whereDic 数据筛选条件key(字段名)，value(字段值)
    func updateDB(_ whereDic: [String: Any]?) {
        
        let key = Self.ck_primarykey() ?? "id"
        var dic = whereDic
        if whereDic == nil {
            dic = [key: self.propertyKeyValues().filter({ $0.name == key }).first?.value as Any]
        }
        let params = self.propertyKeyValues().filter {
            return !(dic?.keys.contains($0.name))!
        }
        DBManager.standard.updateDB(Self.ck_tableName(), propetise: params, whereDic: dic)
        
    }
    
    ///删除某条数据
    ///whereDic 数据筛选条件key(字段名)，value(字段值)
    func deleteDB(_ whereDic: [String: Any]?, completed: Completed?) {
        let key = Self.ck_primarykey() ?? "id"
        var dic = whereDic
        if whereDic == nil {
            dic = [key: self.propertyKeyValues().filter({ $0.name == key }).first?.value as Any]
        }
        DBManager.standard.deleteDB(Self.ck_tableName(), whereDic: dic, completed: completed)
    }
    
    ///当前模型的字段和值
    func propertyKeyValues() -> [PropertyModel] {
        
        var array: [PropertyModel] = []
        let mirror = Mirror.init(reflecting: self)
        for (name, value) in (mirror.children) {
            let propety = PropertyModel.init(name: name, value: value, type: nil, DBType: nil, offset: nil)
            array.append(propety)
        }
        return array
    }
    
    ///whereDic 模糊查询key(字段名)，value(字段值)
    static func selectModelLike(_ whereDic: [String: Any]?, order: String?) -> [Any] {
        var sql = "SELECT * FROM " + self.ck_tableName()
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
    static func selectModel(_ whereDic: [String: Any]?) -> [Any] {
        return self.selectModel(whereDic, order: nil, isOr: false)
    }
    
    static func selectModel(_ whereDic: [String: Any]?, isOr: Bool) -> [Any] {
        return self.selectModel(whereDic, order: nil, isOr: isOr)
    }
    ///查询按某个字段排序（默认降序）
    static func selectModel(_ whereDic: [String: Any]?, order: String?) -> [Any] {
        return self.selectModel(whereDic, order: order, isOr: false)
        
    }
    
    static func selectModel(_ whereDic: [String: Any]?, order: String?, isOr: Bool) -> [Any] {
        let rs = DBManager.standard.selectDB(whereDic, type: self, order: order, isOr: isOr)
        let array = rs.map({ (obj) -> Self? in
            if let dic = obj as? [String: Any] {
                return self.setPropetyValue(dic)
            }
            return nil
        })
//            .filter({ $0 != nil })
        return array as [Any]
        
    }
    
    ///查询当前表的数据
    static func selectModel(_ sql: String) -> [Any] {
        let rs = DBManager.standard.selectDB(sql, type: self)
        
        return rs
        
    }
    
    ///删除某条数据
    ///whereDic 数据筛选条件key(字段名)，value(字段值), nil则清空当前表所有数据
    static func deleteDB(_ whereDic: [String: Any]?, completed: Completed?) {
        
        DBManager.standard.deleteDB(self.ck_tableName(), whereDic: whereDic, completed: completed)
    }
    
//    ///清空表数据
//    static func clearTable(_ completed: Completed?) {
//        DBManager.standard.deleteDB(self.ck_tableName(), whereDic: nil, completed: completed)
//    }
}

