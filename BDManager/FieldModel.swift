//
//  FieldModel.swift
//  net
//
//  Created by 陈凯文 on 2019/9/17.
//  Copyright © 2019 陈凯文. All rights reserved.
//

import UIKit


struct FieldDescriptor {
    
    var pointer: UnsafePointer<_FieldDescriptor>
    
    var fieldRecordSize: Int {
        return Int(pointer.pointee.fieldRecordSize)
    }
    
    var numFields: Int {
        return Int(pointer.pointee.numFields)
    }
    
    var fieldRecords: [FieldRecord] {
        return (0..<numFields).map({ (i) -> FieldRecord in
            return FieldRecord(pointer: UnsafePointer<_FieldRecord>(pointer + 1) + i)
        })
    }
}

struct _FieldDescriptor {
    var mangledTypeNameOffset: Int32
    var superClassOffset: Int32
    //    var fieldDescriptorKind: FieldDescriptorKind
    var fieldRecordSize: Int16
    var numFields: Int32
}

struct FieldRecord {
    
    var pointer: UnsafePointer<_FieldRecord>
    
    var fieldRecordFlags: Int {
        return Int(pointer.pointee.fieldRecordFlags)
    }
    
    var mangledTypeName: UnsafePointer<UInt8>? {
        let address = Int(bitPattern: pointer) + 1 * 4
        let offset = Int(pointer.pointee.mangledTypeNameOffset)
        let cString = UnsafePointer<UInt8>(bitPattern: address + offset)
        return cString
    }
    
    var fieldName: String {
        let address = Int(bitPattern: pointer) + 2 * 4
        let offset = Int(pointer.pointee.fieldNameOffset)
        if let cString = UnsafePointer<UInt8>(bitPattern: address + offset) {
            return String(cString: cString)
        }
        return ""
    }
}

struct _FieldRecord {
    var fieldRecordFlags: Int32
    var mangledTypeNameOffset: Int32
    var fieldNameOffset: Int32
}


public struct PropertyModel {
    ///属性名称
    var name: String!
    ///属性值
    var value: Any!
    ///属性类型
    var type: Any.Type!
    ///数据类型
    var DBType: String!
    ///内存中位移
    var offset: Int!
}


//func properties(_ type: Any.Type) -> [PropertyModelx] {
//    let hashedType = HashedType(type)
//    if let properties = cachedProperties[hashedType] {  // 有缓存直接取值
//        return properties
//    } else {  // 取得包装好的属性, 并设置缓存
//        
//        let properties = propertyDescriptions
//        cachedProperties[hashedType] = properties
//        return properties
//    }
//}
//
//// property 缓存
//struct HashedType : Hashable {
//    let hashValue: Int
//    init(_ type: Any.Type) {
//        hashValue = unsafeBitCast(type, to: Int.self)
//    }
//    init<T>(_ pointer: UnsafePointer<T>) {
//        hashValue = pointer.hashValue
//    }
//}
//
//func == (lhs: HashedType, rhs: HashedType) -> Bool {
//    return lhs.hashValue == rhs.hashValue
//}
