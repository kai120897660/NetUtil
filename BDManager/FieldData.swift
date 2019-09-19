//
//  FieldData.swift
//  net
//
//  Created by 陈凯文 on 2019/9/17.
//  Copyright © 2019 陈凯文. All rights reserved.
//

import UIKit


@_silgen_name("swift_getTypeByMangledNameInContext")
public func _getTypeByMangledNameInContext(
    _ name: UnsafePointer<UInt8>,
    _ nameLength: Int,
    genericContext: UnsafeRawPointer?,
    genericArguments: UnsafeRawPointer?)
    -> Any.Type?

protocol ContextDescriptorProtocol {
    var mangledName: Int { get }
    var numberOfFields: Int { get }
    var fieldOffsetVector: Int { get }
    var reflectionFieldDescriptor: Int { get }
}

struct ContextDescriptor<T: _ContextDescriptorProtocol>: ContextDescriptorProtocol {
    
    var pointer: UnsafePointer<T>
    
    var mangledName: Int {
        return Int(pointer.pointee.mangledNameOffset)
    }
    
    var numberOfFields: Int {
        return Int(pointer.pointee.numberOfFields)
    }
    
    var fieldOffsetVector: Int {
        return Int(pointer.pointee.fieldOffsetVector)
    }
    
    var fieldTypesAccessor: Int {
        return Int(pointer.pointee.fieldTypesAccessor)
    }
    
    var reflectionFieldDescriptor: Int {
        return Int(pointer.pointee.reflectionFieldDescriptor)
    }
}

protocol _ContextDescriptorProtocol {
    var mangledNameOffset: Int32 { get }
    var numberOfFields: Int32 { get }
    var fieldOffsetVector: Int32 { get }
    var fieldTypesAccessor: Int32 { get }
    var reflectionFieldDescriptor: Int32 { get }
}

struct _StructContextDescriptor: _ContextDescriptorProtocol {
    
    var flags: Int32
    var parent: Int32
    var mangledNameOffset: Int32
    var fieldTypesAccessor: Int32
    var reflectionFieldDescriptor: Int32
    var numberOfFields: Int32
    var fieldOffsetVector: Int32
}


extension UnsafePointer {
    init<T>(_ pointer: UnsafePointer<T>) {
        self = UnsafeRawPointer(pointer).assumingMemoryBound(to: Pointee.self)
    }
}
