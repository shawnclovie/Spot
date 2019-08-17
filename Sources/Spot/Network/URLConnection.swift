//
//  URLConnection.swift
//  Spot
//
//  Created by Shawn Clovie on 12/30/15.
//  Copyright © 2015 Shawn Clovie. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

public final class URLConnection: NSObject, URLSessionDownloadDelegate, URLSessionDataDelegate {
	
	private static var runningInstances: Set<URLConnection> = []
	
	public static let `default` = URLConnection()
	
	public var config = URLSessionConfiguration.default
	
	/// use URLSessionTask#taskIdentify as key
	private var tasks: [Int: (task: URLTask, sessionTask: URLSessionTask)] = [:]
	private var session: URLSession?
	private let lock = DispatchSemaphore(value: 1)
	
	func createSessionTask(with task: URLTask) -> URLSessionTask {
		let sessionTask: URLSessionTask = lockFor({
			let session: URLSession
			if let v = self.session {
				session = v
			} else {
				session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
				self.session = session
			}
			let sessionTask: URLSessionTask
			switch task.mode {
			case .data:
				sessionTask = session.dataTask(with: task.urlRequest)
			case .download(_):
				sessionTask = session.downloadTask(with: task.urlRequest)
			case .uploadWithHTTPBody:
				sessionTask = session.uploadTask(with: task.urlRequest, from: task.urlRequest.httpBody ?? Data())
			case .upload(let source):
				switch source {
				case .url(let url):
					sessionTask = session.uploadTask(with: task.urlRequest, fromFile: url)
				case .data(let data):
					sessionTask = session.uploadTask(with: task.urlRequest, from: data)
				}
			}
			tasks[sessionTask.taskIdentifier] = (task, sessionTask)
			return sessionTask
		})
		if self != .default {
			DispatchQueue.main.async {
				Self.runningInstances.insert(self)
			}
		}
		return sessionTask
	}
	
	func remove(_ task: URLTask) {
		lockFor {
			if let it = task.sessionTask {
				tasks.removeValue(forKey: it.taskIdentifier)
			}
			if self != .default && tasks.isEmpty {
				session?.finishTasksAndInvalidate()
				session = nil
				DispatchQueue.main.async {
					Self.runningInstances.remove(self)
				}
			}
		}
	}
	
	private func lockFor<T>(_ closure: ()->T) -> T {
		lock.wait()
		let r = closure()
		lock.signal()
		return r
	}
	
	// MARK: Download Task Delegate
	
	public func urlSession(_ session: URLSession,
	                       downloadTask: URLSessionDownloadTask,
	                       didWriteData bytesWritten: Int64,
	                       totalBytesWritten: Int64,
	                       totalBytesExpectedToWrite: Int64) {
		guard let task = tasks[downloadTask.taskIdentifier]?.task else {return}
		task.didProgress(.init(bytesWritten: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpected: totalBytesExpectedToWrite))
	}
	
	public func urlSession(_ session: URLSession,
	                       downloadTask: URLSessionDownloadTask,
	                       didFinishDownloadingTo location: URL) {
		guard let task = tasks[downloadTask.taskIdentifier]?.task else {return}
		task.didDownload(to: location)
	}
	
	// MARK: Upload Task
	
	public func urlSession(_ session: URLSession,
	                       task: URLSessionTask,
	                       didSendBodyData bytesSent: Int64,
	                       totalBytesSent: Int64,
	                       totalBytesExpectedToSend: Int64) {
		guard let task = tasks[task.taskIdentifier]?.task else {return}
		let progress = URLTask.Progress(
			bytesWritten: bytesSent,
			totalBytesWritten: totalBytesSent,
			totalBytesExpected: totalBytesExpectedToSend)
		task.didProgress(progress)
	}
	
	// MARK: Data Task Delegate
	
	public func urlSession(_ session: URLSession,
	                       dataTask: URLSessionDataTask,
	                       didReceive response: URLResponse,
	                       completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
		guard let task = tasks[dataTask.taskIdentifier]?.task else {return}
		#if os(iOS)
		UIApplication.shared.spot.set(networkActivityIndicatorVisible: true)
		#endif
		task.didReceive(response)
		completionHandler(.allow)
	}
	
	public func urlSession(_ session: URLSession,
	                       dataTask: URLSessionDataTask,
	                       didReceive data: Data) {
		guard let task = tasks[dataTask.taskIdentifier]?.task else {return}
		task.didReceive(data)
	}
	
	// MARK: Task Delegate
	
	public func urlSession(_ session: URLSession,
	                       task: URLSessionTask,
	                       didCompleteWithError error: Error?) {
		guard let task = tasks[task.taskIdentifier]?.task else {return}
		#if os(iOS)
		UIApplication.shared.spot.set(networkActivityIndicatorVisible: false)
		#endif
		remove(task)
		task.didComplete(with: error.map{.init(.network, original: $0)})
	}
	
	public func urlSession(_ session: URLSession,
	                       didBecomeInvalidWithError error: Error?) {
		#if os(iOS)
		UIApplication.shared.spot.set(networkActivityIndicatorVisible: false)
		#endif
		let error = AttributedError(.network, original: error)
		for it in tasks.values {
			remove(it.task)
			it.task.didComplete(with: error)
		}
	}
}
