//
//  NetworkObserver.swift
//  Spot
//
//  Created by Shawn Clovie on 1/9/2017.
//  Copyright © 2017 Shawn Clovie. All rights reserved.
//

import Foundation
import SystemConfiguration

public final class NetworkObserver {
	
	public enum Status {
		case notReachable, wifi, wwan
	}
	
	public enum ReachType {
		case host, address, wifi
	}
	
	/// Network status did change, no object and userInfo. It'd posted on main queue.
	public static let statusDidChangeEvent = EventObservable<Void>(name: "network.statusDidChange")
	
	public static var withInternet: NetworkObserver? {
		var addr = sockaddr_in()
		addr.sin_len = UInt8(MemoryLayout.size(ofValue: addr))
		addr.sin_family = sa_family_t(AF_INET)
		return NetworkObserver(address: addr)
	}
	
	public static var withWiFi: NetworkObserver? {
		var addr = sockaddr_in()
		addr.sin_len = UInt8(MemoryLayout.size(ofValue: addr))
		addr.sin_family = sa_family_t(AF_INET)
		addr.sin_addr.s_addr = CFSwapInt32HostToBig(IN_LINKLOCALNETNUM)
		return NetworkObserver(address: addr, type: .wifi)
	}
	
	public let type: ReachType
	private let reachability: SCNetworkReachability
	public private(set) var isObserving = false
	
	private init(reachability: SCNetworkReachability, type: ReachType) {
		self.reachability = reachability
		self.type = type
	}
	
	public convenience init?(address: sockaddr_in, type: ReachType = .address) {
		var address = address
		guard let reach = withUnsafePointer(to: &address, { pointer in
			pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
				SCNetworkReachabilityCreateWithAddress(nil, $0)
			}
		}) else {
			return nil
		}
		self.init(reachability: reach, type: type)
	}
	
	public convenience init?(host: String) {
		guard let reach = SCNetworkReachabilityCreateWithName(nil, host) else {
			return nil
		}
		self.init(reachability: reach, type: .host)
	}
	
	deinit {
		stopObserve()
	}
	
	public var currentStatus: Status {
		var flags = SCNetworkReachabilityFlags(rawValue: 0)
		return SCNetworkReachabilityGetFlags(reachability, &flags)
			? type == .wifi ? flags.wifiStatus : flags.networkStatus
			: .notReachable
	}
	
	public var isConnectionRequired: Bool {
		var flags = SCNetworkReachabilityFlags(rawValue: 0)
		return SCNetworkReachabilityGetFlags(reachability, &flags)
			&& flags.contains(.connectionRequired)
	}

	@discardableResult
	public func startObserve() -> Bool {
		if !isObserving {
			let info = Unmanaged<NetworkObserver>.passUnretained(self).toOpaque()
			var context = SCNetworkReachabilityContext(version: 0, info: info, retain: nil, release: nil, copyDescription: nil)
			if (SCNetworkReachabilitySetCallback(reachability, NetworkReachabilityCallback, &context) &&
				SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)) {
				isObserving = true
			}
		}
		return isObserving
	}
	
	public func stopObserve() {
		SCNetworkReachabilityUnscheduleFromRunLoop(reachability, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
		isObserving = false
	}
}

private func NetworkReachabilityCallback(target: SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutableRawPointer?) {
	DispatchQueue.main.async {
		NetworkObserver.statusDidChangeEvent.dispatch(())
	}
}

// MARK: Network Flag Handling
extension SCNetworkReachabilityFlags {
	fileprivate var wifiStatus: NetworkObserver.Status {
		contains(.reachable) && contains(.isDirect) ? .wifi : .notReachable
	}
	
	fileprivate var networkStatus: NetworkObserver.Status {
		if !contains(.reachable) {
			return .notReachable
		}
		var retVal: NetworkObserver.Status = .notReachable
		if !contains(.connectionRequired) {
			// if target host is reachable and no connection is required then we'll assume (for now) that your on Wi-Fi
			retVal = .wifi
		}
		if contains(.connectionOnDemand) || contains(.connectionOnTraffic) {
			// ... and the connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs
			if !contains(.interventionRequired) {
				// ... and no [user] intervention is needed
				retVal = .wifi
			}
		}
		#if !os(macOS)
		if contains(.isWWAN) {
			// ... but WWAN connections are OK if the calling application is using the CFNetwork (CFSocketStream?) APIs.
			retVal = .wwan
		}
		#endif
		return retVal
	}
}
