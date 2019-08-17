//
//  CollectionSerializable.swift
//  Spot
//
//  Created by Shawn Clovie on 5/6/2017.
//  Copyright © 2017 Shawn Clovie. All rights reserved.
//

public typealias DictionaryCodable = DictionaryEncodable & DictionaryDecodable

public protocol DictionaryEncodable {
	var encodedDictionary: [AnyHashable: Any] {get}
}

public protocol DictionaryDecodable {
	init(encoded: [AnyHashable: Any])
}

public typealias ArrayCodable = ArrayEncodable & ArrayDecodable

public protocol ArrayEncodable {
	var encodedArray: [Any] {get}
}

public protocol ArrayDecodable {
	init(encoded: [Any])
}
