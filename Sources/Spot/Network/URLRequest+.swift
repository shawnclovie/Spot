//
//  URLRequest+.swift
//  Spot
//
//  Created by Shawn Clovie on 24/02/2017.
//  Copyright © 2017 Shawn Clovie. All rights reserved.
//

import Foundation

public typealias URLKeyValuePairs = [(String, Any)]

extension URLRequest {
	
	/// Easy way to create URLRequest.
	///
	/// - Parameters:
	///   - method: HTTP method
	///   - url: URL
	/// - Returns: URLRequest
	public static func spot(_ method: URLTask.Method, _ url: URL) -> URLRequest {
		var inst = URLRequest(url: url)
		inst.httpMethod = method.rawValue
		return inst
	}
	
	/// Set parameters
	/// - Throws: If parameter's Content-Type is application/json, encode parameters.dictionaryValue may cause error
	public mutating func spot_set(parameters: URLParameters) throws {
		spot_append(headers: parameters.headers)
		if parameters.headers[URLTask.contentTypeKey] == URLTask.contentTypeJSON {
			httpBody = try JSONSerialization.data(withJSONObject: parameters.encodedDictionary)
		} else {
			spot_set(parameters: parameters.keyValuePairs, .urlEncoded)
		}
	}
	
	public mutating func spot_append(headers: [String: String]) {
		if var curValue = allHTTPHeaderFields {
			for it in headers {
				curValue[it.key] = it.value
			}
			allHTTPHeaderFields = curValue
		} else {
			allHTTPHeaderFields = headers
		}
	}
	
	public mutating func spot_append(queryString: URLKeyValuePairs) {
		guard let url = url else {return}
		let urlString = url.absoluteString + (url.query == nil ? "?" : "&") + String.spot(queryString: queryString)
		self.url = URL(string: urlString) ?? url
	}
	
	public mutating func spot_set(modifiedSince: String) {
		addValue(modifiedSince, forHTTPHeaderField: "If-Modified-Since")
	}
	
	/// Set parameters by http method
	///
	/// - Parameters:
	///   - parameters: Querystring for get, or http body for other method
	///   - encType: Encode Type
	public mutating func spot_set(parameters: URLKeyValuePairs, _ encType: URLTask.FormEncodeType = .urlEncoded) {
		switch URLTask.Method(rawValue: httpMethod?.lowercased() ?? "") ?? .get {
		case .get:
			spot_append(queryString: parameters)
		default:
			spot_set(httpBody: parameters, encType)
		}
	}
	
	public mutating func spot_set(httpBody params: URLKeyValuePairs, _ encType: URLTask.FormEncodeType = .urlEncoded) {
		switch encType {
		case .multipartFormData:
			let (boundary, data) = params.encodedMultipartFormData
			if !data.isEmpty {
				httpBody = data
				setValue("multipart/form-data; boundary=" + boundary, forHTTPHeaderField: URLTask.contentTypeKey)
			}
		case .textPlain:
			httpBody = Data(String.spot(queryString: params, encode: false).utf8)
		case .urlEncoded:
			httpBody = Data(String.spot(queryString: params).utf8)
		}
	}
}

extension URLKeyValuePairs {
	/// Encode as multipart/form-data, returns boundary and data
	public var encodedMultipartFormData: (String, Data) {
		let boundary = UUID().uuidString
		var body = Data()
		let dataCRLF = Data("\r\n".utf8)
		let dataItemDelimit = Data(("--" + boundary).utf8)
		for (key, value) in self {
			autoreleasepool {
				guard var bodyItemHead = "Content-Disposition: form-data;name=\"\(key)\"".data(using: .utf8) else {
					return
				}
				let bodyItemData: Data
				if let fileItem = value as? URLTaskFormFileItem {
					let contentType = fileItem.contentType ??
						URLTask.mimeType(filename: fileItem.filename)
					var fileHead = ";filename=\"\(fileItem.filename)\""
					for (key, value) in fileItem.meta {
						fileHead += ";\(key)=\"\(value)\""
					}
					fileHead += "\r\nContent-Type: \(contentType)"
					if let fileData = fileItem.source.data {
						bodyItemHead.append(Data(fileHead.utf8))
						bodyItemData = fileData
					} else {
						return
					}
				} else {
					bodyItemData = Data(String(describing: value).utf8)
				}
				body.append(dataItemDelimit)
				body.append(dataCRLF)
				body.append(bodyItemHead)
				body.append(dataCRLF)
				body.append(dataCRLF)
				body.append(bodyItemData)
				body.append(dataCRLF)
			}
		}
		body.append(dataItemDelimit)
		body.append(Data("--".utf8))
		body.append(dataCRLF)
		return (boundary, body)
	}
}
