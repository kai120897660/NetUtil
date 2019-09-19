//
//  ModelOpreateUtil.swift
//  net
//
//  Created by 陈凯文 on 2019/9/18.
//  Copyright © 2019 陈凯文. All rights reserved.
//

import UIKit

public protocol CKPropetyDescriptor {
    ///当前类型中不需要存入数据库的属性
    static func ck_ignoresProperties() -> [String]?
    
    static var properties: [PropertyModel]? {get}
}

extension CKPropetyDescriptor {
    static var pointer: UnsafePointer<Int>! {
        let superType = Self.self as Any.Type
        // 类型转化
        let pointer = unsafeBitCast(superType, to: UnsafePointer<Int>.self)
        return pointer
    }
    
    ///结构体属性和类型
    static var properties: [PropertyModel]? {
        
        let base = self.pointer.advanced(by: 1)  // contextDescriptorOffsetLocation
        
        // 相对指针偏移值
        let relativePointerOffset = base.pointee - Int(bitPattern: base)
        
        let descriptor = ContextDescriptor<_StructContextDescriptor>.init(pointer: UnsafeRawPointer(base).advanced(by: relativePointerOffset).assumingMemoryBound(to: _StructContextDescriptor.self))
        
        
        let fields = Int(descriptor.numberOfFields)
        
        let offset = descriptor.reflectionFieldDescriptor
        let address = base.pointee + 4 * 4 // (4 properties in front) * (sizeof Int32)
        let fieldDescriptorPtr = UnsafePointer<_FieldDescriptor>(bitPattern: address + offset)
        let fieldDescriptor = FieldDescriptor.init(pointer: fieldDescriptorPtr!)
        
        
        return (0..<fields).map { (i) -> PropertyModel in
            
            let mangledType = fieldDescriptor.fieldRecords[i].mangledTypeName
            let fieldType = _getTypeByMangledNameInContext(mangledType!, 256, genericContext: UnsafeRawPointer(bitPattern: base.pointee), genericArguments: UnsafeRawPointer(pointer.advanced(by: 2)))
            let fieldName = fieldDescriptor.fieldRecords[i].fieldName
            print(fieldName, fieldType!)
            let DBType = self.getPropertyType(fieldType)
            
            let offset = Int(UnsafePointer<Int32>(pointer)[descriptor.fieldOffsetVector * 2 + i])
            
            return PropertyModel(name: fieldName, value: nil, type: fieldType, DBType: DBType, offset: offset)
            }.filter({ property in
                guard let ignoreArray = self.ck_ignoresProperties() else {
                    return true
                }
                return !ignoreArray.contains(property.name)
            })
    }
    
    ///存入数据库的类型
    static func getPropertyType(_ type: Any.Type?) -> String {
        guard let type = type else {
            return ""
        }
        if type == Bool.self || type == Bool?.self {
            return "TINYINT"
        }else if type == (Int, Int8, Int32,Int?, Int8?, Int32?).self {
            return "INTEGER"
        }else if type == CGFloat.self || type == CGFloat?.self ||
            type == Float.self || type == Float?.self ||
            type == Double.self || type == Double?.self ||
            type == NSNumber.self || type == NSNumber?.self {
            return "DECIMAL"
        }
        else if type == String.self || type == String?.self {
            return "TEXT"
        }
        return ""
    }
    
    static func ck_ignoresProperties() -> [String]? {
        return nil
    }
}

public protocol CKModelOpreate: CKPropetyDescriptor {
    init()
}

extension CKModelOpreate {
    
    // 获取头指针
    static func headPointerOfStruct<T>(instance: inout T) -> UnsafeMutablePointer<Int8> {
        return withUnsafeMutablePointer(to: &instance) {
            return UnsafeMutableRawPointer($0).bindMemory(to: Int8.self, capacity: MemoryLayout<T>.stride)
        }
    }
    
    static func setPropetyValue(_ dict: [String: Any]) -> Self {
        // 获取头指针
        var model = Self.init()
        let rawPointer = headPointerOfStruct(instance: &model)
        
        // 获取数据
        //        let dict: [String: Any] = ["isBoy": true, "name": "lili", "age": 18, "height": 100.123]
        
        // 遍历属性
        for property in self.properties! {
            let propAddr = rawPointer.advanced(by: property.offset)
            
            if let rawValue = dict[property.name] {
                extensions(of: property.type).write(rawValue, to: propAddr)
            }
        }
        print("\n model \n", model)
        return model
    }

}



protocol AnyExtensions {}

extension AnyExtensions {
    public static func write(_ value: Any, to storage: UnsafeMutableRawPointer) {
        guard let this = value as? Self else {
            print("类型转换失败, \(type(of: value))无法转为\(Self.self)")
            
            return
        }
        storage.assumingMemoryBound(to: self).pointee = this
    }
}
func extensions(of type: Any.Type) -> AnyExtensions.Type {
    struct Extensions : AnyExtensions {}
    var extensions: AnyExtensions.Type = Extensions.self
    
    withUnsafePointer(to: &extensions) { pointer in
        UnsafeMutableRawPointer(mutating: pointer).assumingMemoryBound(to: Any.Type.self).pointee = type
    }
    return extensions
}
