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

open class URLConnection: NSObject, URLSessionDownloadDelegate, URLSessionDataDelegate {
	
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
				case .path(let it):
					sessionTask = session.uploadTask(with: task.urlRequest, fromFile: it)
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
		guard let it = task.sessionTask else {return}
		removeTask(it.taskIdentifier)
	}
	
	@discardableResult
	private func removeTask(_ taskID: Int) -> (URLTask, URLSessionTask)? {
		lockFor {
			let it = tasks.removeValue(forKey: taskID)
			if self != .default && tasks.isEmpty {
				session?.finishTasksAndInvalidate()
				session = nil
				DispatchQueue.main.async {
					Self.runningInstances.remove(self)
				}
			}
			return it
		}
	}
	
	private func lockFor<T>(_ closure: ()->T) -> T {
		lock.wait()
		let r = closure()
		lock.signal()
		return r
	}
	
	// MARK: Download Task Delegate
	
	open func urlSession(_ session: URLSession,
	                     downloadTask: URLSessionDownloadTask,
	                     didWriteData bytesWritten: Int64,
	                     totalBytesWritten: Int64,
	                     totalBytesExpectedToWrite: Int64) {
		guard let it = tasks[downloadTask.taskIdentifier] else {return}
		it.task.didProgress(.init(
			bytesWritten: bytesWritten,
			totalBytesWritten: totalBytesWritten,
			totalBytesExpected: totalBytesExpectedToWrite))
	}
	
	open func urlSession(_ session: URLSession,
	                     downloadTask: URLSessionDownloadTask,
	                     didFinishDownloadingTo location: URL) {
		guard let it = tasks[downloadTask.taskIdentifier] else {return}
		it.task.didDownload(to: location)
	}
	
	// MARK: Upload Task
	
	open func urlSession(_ session: URLSession,
	                     task: URLSessionTask,
	                     didSendBodyData bytesSent: Int64,
	                     totalBytesSent: Int64,
	                     totalBytesExpectedToSend: Int64) {
		guard let it = tasks[task.taskIdentifier] else {return}
		it.task.didProgress(.init(
			bytesWritten: bytesSent,
			totalBytesWritten: totalBytesSent,
			totalBytesExpected: totalBytesExpectedToSend))
	}
	
	// MARK: Data Task Delegate
	
	open func urlSession(_ session: URLSession,
						 dataTask: URLSessionDataTask,
	                     didReceive response: URLResponse,
	                     completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
		guard let it = tasks[dataTask.taskIdentifier] else {return}
		#if os(iOS)
		UIApplication.shared.spot.set(networkActivityIndicatorVisible: true)
		#endif
		it.task.didReceive(response)
		completionHandler(.allow)
	}
	
	open func urlSession(_ session: URLSession,
						 dataTask: URLSessionDataTask,
						 didReceive data: Data) {
		guard let task = tasks[dataTask.taskIdentifier]?.task else {return}
		task.didReceive(data)
	}
	
	// MARK: Task Delegate
	
	open func urlSession(_ session: URLSession, task: URLSessionTask,
						 didCompleteWithError error: Error?) {
		guard let it = tasks[task.taskIdentifier] else {return}
		#if os(iOS)
		UIApplication.shared.spot.set(networkActivityIndicatorVisible: false)
		#endif
		removeTask(task.taskIdentifier)
		it.task.didComplete(with: error.map{.init(.network, original: $0)})
	}
	
	open func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
		#if os(iOS)
		UIApplication.shared.spot.set(networkActivityIndicatorVisible: false)
		#endif
		var tasks: [URLTask] = []
		lockFor {
			tasks = self.tasks.map{(_, it) in it.task}
			self.tasks.removeAll()
		}
		let error = AttributedError(.network, original: error)
		for it in tasks {
			it.didComplete(with: error)
		}
	}
}
