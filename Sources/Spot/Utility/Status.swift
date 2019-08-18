//
//  Status.swift
//  Spot
//
//  Created by Shawn Clovie on 1/20/16.
//  Copyright © 2016 Shawn Clovie. All rights reserved.
//

/// Status of an operation
///
/// - resulted: Operation did finish with succeed or failed.
/// - processing: Operation is processing.
/// - cancelled: Operation did cancelled.
/// - idle: Currently doing nothing.
public enum Status<T, E: Error> {
	
	case resulted(Result<T, E>)
	case processing
	case cancelled
	case idle
	
	public var result: Result<T, E>? {
		if case .resulted(let result) = self {
			return result
		}
		return nil
	}
}
