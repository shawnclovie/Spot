//
//  URLTask.swift
//  Spot
//
//  Created by Shawn Clovie on 01/04/2017.
//  Copyright © 2017 Shawn Clovie. All rights reserved.
//

import Foundation
#if os(macOS)
import CoreServices
#else
import MobileCoreServices
#endif
#if canImport(UIKit)
import UIKit
#endif

public final class URLTask: Hashable {
	
	public enum Method: String {
		case get, post, put, delete
	}
	
	public enum FormEncodeType {
		case textPlain
		case urlEncoded
		case multipartFormData
	}
	
	public enum Mode {
		case data
		case download(saveAsFile: URL)
		case uploadWithHTTPBody
		case upload(Data.Source)
	}
	
	public struct Progress {
		public var bytesWritten: Int64 = 0
		public var totalBytesWritten: Int64 = 0
		public var totalBytesExpected: Int64 = 0
		
		public var percentage: Double {
			totalBytesExpected <= 0 ? 0 : Double(totalBytesWritten) / Double(totalBytesExpected)
		}
	}
	
	public static let contentEncodingKey = "Content-Encoding"
	public static let contentLengthKey = "Content-Length"
	public static let contentTypeKey = "Content-Type"
	public static let contentTypeJSON = "application/json"
	public static let contentTypeOctet = "application/octet-stream"
	
	public static func mimeType(filename: String) -> String {
		guard let ext = filename.spot.pathExtension,
			let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ext as CFString, nil),
			let type = UTTypeCopyPreferredTagWithClass(uti.takeRetainedValue(), kUTTagClassMIMEType)
			else {return contentTypeOctet}
		return type.takeRetainedValue() as String
	}
	
	public private(set) var progress = Progress()
	public private(set) var sessionTask: URLSessionTask?
	public private(set) var urlRequest: URLRequest
	
	public let progressEvent = EventObservable<Progress>()
	public var completeEvent = EventObservable<(URLTask, AttributedResult<Data>)>()
	public let downloadedEvent = EventObservable<(URL, Error?)>()
	
	public let mode: Mode
	public private(set) var respondData = Data()
	public private(set) var respondHeaders: [AnyHashable: Any] = [:]
	/// Queue to call each progress, complete and downloaded events.
	private var handlerQueue: DispatchQueue = .main
	private weak var connection: URLConnection?
	#if os(iOS)
	private var backgroundTaskHandler: (()->Void)?
	#endif
	
	public init(_ request: URLRequest, for mode: Mode = .data) {
		self.mode = mode
		urlRequest = request
		if urlRequest.httpMethod?.lowercased() != Method.get.rawValue {
			urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
			urlRequest.httpShouldHandleCookies = false
		}
	}
	
	public func hash(into hasher: inout Hasher) {
		urlRequest.hash(into: &hasher)
	}
	
	public var isRunning: Bool {
		guard let task = sessionTask else {return false}
		return task.state == .running
	}
	
	public var url: URL? {urlRequest.url}
	
	public var response: URLResponse? {sessionTask?.response}
	
	public var respondStatusCode: Int? {
		(sessionTask?.response as? HTTPURLResponse)?.statusCode
	}
	
	/// Get header of response for name, or lowercased name in it (some gateway may lowercased all header's name)
	public func respondHeader(_ name: String) -> Any? {
		guard let value = respondHeaders[name] ?? respondHeaders[name.lowercased()]
			else {return nil}
		return value
	}
	
	public var respondLastModified: String? {
		respondHeader("Last-Modified") as? String
	}
	
	public var requestHeaders: [String: String]? {
		get {urlRequest.allHTTPHeaderFields}
		set {
			guard !isRunning else {return}
			urlRequest.allHTTPHeaderFields = newValue
		}
	}
	
	public func append(headers: [String: String]) {
		urlRequest.spot_append(headers: headers)
	}
	
	@discardableResult
	public func set(parameters: [String: Any], _ encType: FormEncodeType = .urlEncoded) -> Self {
		if !isRunning {
			var params: URLKeyValuePairs = []
			params.reserveCapacity(parameters.count)
			for (key, value) in parameters {
				params.append((key, value))
			}
			urlRequest.spot_set(parameters: params, encType)
		}
		return self
	}
	
	/// - Throws: If parameter's Content-Type is application/json, encode parameters.dictionaryValue may cause error
	@discardableResult
	public func set(parameters: URLParameters) throws -> Self {
		if !isRunning {
			try urlRequest.spot_set(parameters: parameters)
		}
		return self
	}
	
	/// Set HTTP body
	///
	/// - Parameters:
	///   - parameters: Parameters, as query string for get, as http body otherwise.
	///   - encType: Parameters encode type, equals "enctype" in html <form>.
	@discardableResult
	public func set(parameters: URLKeyValuePairs, _ encType: FormEncodeType = .urlEncoded) -> Self {
		if !isRunning {
			urlRequest.spot_set(parameters: parameters, encType)
		}
		return self
	}
	
	#if os(iOS)
	@discardableResult
	public func enableBackgroundTask() -> Self {
		UIApplication.shared.spot.beginBackgroundTask {
			backgroundTaskHandler = $0
		}
		return self
	}
	#endif
	
	/// Start data or download task.
	///
	/// - Parameters:
	///   - conn: URLConnection use to make request, default as .default.
	///   - priority: Priority of the task, between 0 and 1, default as URLSessionTask.defaultPriority.
	///   - queue: Queue to call handlers, default as .main.
	///   - progression: Progress handler, it would subscribe to progressEvent if given.
	///   - completion: Completion handler, it would subscribe to completeEvent if given.
	@discardableResult
	public func request(with conn: URLConnection = .default,
						priority: Float = URLSessionTask.defaultPriority,
	                    queue: DispatchQueue = .main,
	                    progression: ((Progress)->Void)? = nil,
	                    completion: ((URLTask, Result<Data, AttributedError>)->Void)? = nil) -> Self {
		if isRunning {
			cancel()
		}
		respondData.removeAll()
		connection = conn
		handlerQueue = queue
		if let fn = progression {
			_ = progressEvent.subscribe(fn)
		}
		if let fn = completion {
			_ = completeEvent.subscribe(fn)
		}
		let task = conn.createSessionTask(with: self)
		task.priority = priority
		sessionTask = task
		task.resume()
		return self
	}
	
	public func cancel() {
		if let task = sessionTask, task.state == .running {
			task.cancel()
			connection?.remove(self)
		}
		dispose()
	}
	
	func didReceive(_ response: URLResponse) {
		progress.totalBytesWritten = 0
		progress.totalBytesExpected = response.expectedContentLength
		if let resp = response as? HTTPURLResponse {
			respondHeaders = resp.allHeaderFields
		}
	}
	
	func didProgress(_ progress: Progress) {
		self.progress = progress
		progressEvent.dispatch(progress, queue: handlerQueue)
	}
	
	func didReceive(_ data: Data) {
		respondData.append(data)
		progress.bytesWritten = Int64(data.count)
		progress.totalBytesWritten = Int64(respondData.count)
		didProgress(progress)
	}
	
	func didDownload(to location: URL) {
		guard case .download(let path) = mode else {return}
		do {
			if path != location {
				if path.spot.fileExists() {
					try FileManager.default.removeItem(at: path)
				}
				try FileManager.default.moveItem(at: location, to: path)
			}
			downloadedEvent.dispatch((path, nil), queue: handlerQueue)
		} catch {
			downloadedEvent.dispatch((path, error), queue: handlerQueue)
		}
	}
	
	func didComplete(with error: AttributedError?) {
		let result: AttributedResult<Data>
		if let error = error {
			result = .failure(error)
		} else {
			result = .success(respondData)
		}
		completeEvent.dispatch((self, result), queue: handlerQueue)
		dispose()
	}
	
	private func dispose() {
		connection = nil
		#if os(iOS)
		if let fn = backgroundTaskHandler {
			backgroundTaskHandler = nil
			fn()
		}
		#endif
	}
}

public func ==(lhs: URLTask, rhs: URLTask) -> Bool {
	lhs.urlRequest == rhs.urlRequest
}
