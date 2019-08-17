//
//  URLRequest+.swift
//  Spot
//
//  Created by Shawn Clovie on 24/02/2017.
//  Copyright © 2017 Shawn Clovie. All rights reserved.
//

import Foundation

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
	
	public mutating func spot_set(parameters: URLParameters, _ encType: URLTask.FormEncodeType = .urlEncoded) {
		spot_append(headers: parameters.headers)
		return spot_set(parameters: parameters.keyValuePairs, encType)
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
	
	public mutating func spot_append(queryString: [(String, Any)]) {
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
	public mutating func spot_set(parameters: [(String, Any)], _ encType: URLTask.FormEncodeType = .urlEncoded) {
		switch URLTask.Method(rawValue: httpMethod?.lowercased() ?? "") ?? .get {
		case .get:
			spot_append(queryString: parameters)
		case .post:
			spot_set(httpBody: parameters, encType)
		default:
			spot_set(httpBody: parameters, .urlEncoded)
		}
	}
	
	public mutating func spot_set(httpBody params: [(String, Any)], _ encType: URLTask.FormEncodeType = .urlEncoded) {
		switch encType {
		case .multipartFormData:
			let boundary = UUID().uuidString
			setValue("multipart/form-data; boundary=" + boundary, forHTTPHeaderField: "Content-Type")
			var body = Data()
			let dataCRLF = Data("\r\n".utf8)
			let dataItemDelimit = Data(("--" + boundary).utf8)
			for (key, value) in params {
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
			if !body.isEmpty {
				body.append(dataItemDelimit)
				body.append(Data("--".utf8))
				body.append(dataCRLF)
				httpBody = body
			}
		case .textPlain:
			httpBody = Data(String.spot(queryString: params, encode: false).utf8)
		case .urlEncoded:
			httpBody = Data(String.spot(queryString: params).utf8)
		}
	}
}
