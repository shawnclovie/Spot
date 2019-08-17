//
//  Error+extension.swift
//  Spot
//
//  Created by Shawn Clovie on 7/10/2017.
//  Copyright © 2017 Shawn Clovie. All rights reserved.
//

public protocol LocalizedDescriptable {
	var localizedDescription: String {get}
}

public protocol ErrorConvertable {
	init(with err: Error)
}

extension Error {
	
	public var spot_localizedDescription: String {
		switch self {
		case let err as LocalizedDescriptable:
			return err.localizedDescription
		default:
			return localizedDescription
		}
	}
}
