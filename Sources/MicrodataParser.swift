import Foundation
import Kanna

enum Attribute: String {
    case itemScope      = "itemscope"
    case itemProperty   = "itemprop"
    case itemType       = "itemtype"
    case itemReference  = "itemref"
    case itemID         = "itemid"
}

enum PropertyTag: String {
    case meta   = "meta"
    case audio  = "audio"
    case embed  = "embed"
    case iframe = "iframe"
    case img    = "img"
    case source = "source"
    case track  = "track"
    case video  = "video"
    case a      = "a"
    case area   = "area"
    case link   = "link"
    case object = "object"
    case data   = "data"
    case meter  = "meter"
    case time   = "time"
    
    var valueAttribute: String {
        switch self {
        case .meta:
            return "content"
        case .audio, .embed, .iframe, .img, .source, .track, .video:
            return "src"
        case .a, .area, .link:
            return "href"
        case .object:
            return "data"
        case .data, .meter:
            return "value"
        case .time:
            return "datetime"
        }
    }
}

extension Kanna.XMLElement {
    
    func has(attribute: Attribute) -> Bool {
        return self[attribute.rawValue] != nil
    }
    
    var isItem: Bool {
        return has(attribute: .itemScope)
    }
    
    var isProperty: Bool {
        return has(attribute: .itemProperty)
    }
    
    var isTyped: Bool {
        return has(attribute: .itemType)
    }
    
    var id: String? {
        return self[Attribute.itemID.rawValue]
    }
    
    var type: String? {
        return self[Attribute.itemType.rawValue]
    }
    
    var reference: String? {
        return self[Attribute.itemReference.rawValue]
    }
    
}

public enum MicrodataError: Error {
    case invalidHTMLDocument
}

public typealias PropertyTransform = (Kanna.XMLElement, Any) throws -> Any?

public final class MicrodataParser {
    
    var propertyTransforms : [String : PropertyTransform] = [:]
    var acceptedSchemas : [String]?
    
    public init(){}
    
    public init(
        acceptedSchemas: [String]? = nil,
        propertyTransforms: [String : PropertyTransform]
        ) {
        self.acceptedSchemas = acceptedSchemas
        self.propertyTransforms = propertyTransforms
    }
    
    public func parse(html: String) throws -> [[String : Any]] {
        guard
            let document = Kanna.HTML(html: html, encoding: .utf8),
            let body = document.body
            else {
                throw MicrodataError.invalidHTMLDocument
        }
        return try parseItems(from: body)
            .map{ try connectReferencedProperties(item: $0, from: body) }
            .map{ $0.objectValue }
    }
    
    func accept(element: Kanna.XMLElement) -> Bool {
        if acceptedSchemas != nil {
            guard let type = element.type else {
                return false
            }
            return acceptedSchemas!.contains(type)
        } else {
            return true
        }
    }
    
    func parseItems(from element: Kanna.XMLElement) throws -> [MicrodataItem] {
        if element.isItem && accept(element: element) {
            return [try parseItem(from: element)]
        } else {
            var items = [MicrodataItem]()
            for child in element.xpath("./*") {
                items += try parseItems(from: child)
            }
            return items
        }
    }
    
    func parseItem(from element: Kanna.XMLElement) throws -> MicrodataItem {
        let item = MicrodataItem()
        if let id = element.id {
            item["@id"] = id
        }
        if let type = element.type {
            item["@type"] = type
        }
        if let ref = element.reference {
            item.itemReference = ref
        }
        for child in element.xpath("./*") {
            try parseProperties(from: child)
                .forEach { (prop) in
                    item[prop.name] = prop.value
            }
        }
        return item
    }
    
    func parseProperties(from element: Kanna.XMLElement) throws -> [(name: String, value: Any)] {
        if element.isProperty {
            let propertyName = element[Attribute.itemProperty.rawValue]!
            var value : Any
            if element.isItem {
                value = try parseItem(from: element)
            } else {
                value = try parseValue(from: element)
            }
            if
                let customTransform = propertyTransforms[propertyName],
                let transformed = try customTransform(element, value) {
                value = transformed
            }
            return [(name: propertyName, value: value)]
        } else {
            var properties = [(name: String, value: Any)]()
            for child in element.xpath("./*") {
                properties += try parseProperties(from: child)
            }
            return properties
        }
    }
    
    func parseValue(from element: Kanna.XMLElement) throws -> Any {
        if let tag = PropertyTag(rawValue: element.tagName!.lowercased()) {
            return element[tag.valueAttribute] ?? ""
        } else {
            return element.text ?? ""
        }
    }
    
    func connectReferencedProperties(item: MicrodataItem,
                                     from element: Kanna.XMLElement) throws -> MicrodataItem {
        for reference in item.references {
            guard let referenced = element.at_xpath(".//*[@id='\(reference)']") else {
                throw MicrodataError.invalidHTMLDocument
            }
            for child in referenced.xpath("./*") {
                try parseProperties(from: child).forEach { (prop) in
                    item[prop.name] = prop.value
                }
            }
        }
        return item
    }
    
}
