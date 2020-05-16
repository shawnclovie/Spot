//
//  AnyCodable.swift
//  Spot
//
//  Created by Shawn Clovie on 16/5/2020.
//

import Foundation

/// A type-based codable value.
public struct AnyCodable {
    public var value: Any
    
    public init<T>(_ value: T?) {
        self.value = value ?? ()
    }
}

extension AnyCodable: Codable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.init(())
        } else if let v = try? container.decode(Bool.self) {
            self.init(v)
        } else if let v = try? container.decode(Int.self) {
            self.init(v)
        } else if let v = try? container.decode(UInt.self) {
            self.init(v)
        } else if let v = try? container.decode(Double.self) {
            self.init(v)
        } else if let v = try? container.decode(String.self) {
            self.init(v)
        } else if let v = try? container.decode([AnyCodable].self) {
			self.init(v.map(\.value))
        } else if let v = try? container.decode([String: AnyCodable].self) {
            self.init(v.mapValues(\.value))
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case is Void:
            try container.encodeNil()
        case let v as Bool:
            try container.encode(v)
        case let v as Int:
            try container.encode(v)
        case let v as Int8:
            try container.encode(v)
        case let v as Int16:
            try container.encode(v)
        case let v as Int32:
            try container.encode(v)
        case let v as Int64:
            try container.encode(v)
        case let v as UInt:
            try container.encode(v)
        case let v as UInt8:
            try container.encode(v)
        case let v as UInt16:
            try container.encode(v)
        case let v as UInt32:
            try container.encode(v)
        case let v as UInt64:
            try container.encode(v)
        case let v as Float:
            try container.encode(v)
        case let v as Double:
            try container.encode(v)
        case let v as String:
            try container.encode(v)
        case let v as Date:
            try container.encode(v)
        case let v as URL:
            try container.encode(v)
        case let v as [Any?]:
			try container.encode(v.map(AnyCodable.init(_:)))
        case let v as [String: Any?]:
			try container.encode(v.mapValues(AnyCodable.init(_:)))
		case let v as CustomStringConvertible:
			try container.encode(v.description)
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded")
            throw EncodingError.invalidValue(value, context)
        }
    }
}
