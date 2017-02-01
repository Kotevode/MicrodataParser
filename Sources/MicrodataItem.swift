//
//  MicrodataItem.swift
//  MicrodataParser
//
//  Created by Mark on 01.02.17.
//
//

import Foundation

class MicrodataItem {
    
    var references = [String]()
    private var entity = [String : Any]()
    
    subscript(key: String) -> Any? {
        get{
            return entity[key]
        }
        set{
            guard let value = newValue else {
                return
            }
            switch entity[key] {
            case let a as [Any]:
                entity[key] = a + [value]
            case let v:
                if let _ = v {
                    entity[key] = [v!, value]
                } else {
                    entity[key] = value
                }
            }
        }
    }
    
    var itemReference: String {
        set{
            references = newValue.components(separatedBy: " ")
        }
        get {
            return references.joined(separator: " ")
        }
    }
    
    var objectValue: [String : Any] {
        var result = [String : Any]()
        for property in entity {
            switch property.value {
            case let array as [Any]:
                result[property.key] = array.map({ (value) -> Any in
                    return transform(value: value)
                })
            default:
                result[property.key] = transform(value: property.value)
            }
        }
        return result
    }
    
    private func transform(value: Any) -> Any {
        switch value {
        case let v as MicrodataItem:
            return v.objectValue
        default:
            return value
        }
    }
}
