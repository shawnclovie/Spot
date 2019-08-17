//
//  UserNotificationManager.swift
//  Spot iOS
//
//  Created by Shawn Clovie on 25/10/2017.
//  Copyright © 2017 Shawn Clovie. All rights reserved.
//

#if canImport(UIKit)
import UserNotifications
import UIKit

public final class UserNotificationManager {
	
	public static let shared = UserNotificationManager()
	
	/// Present UN request dialog, it would only worked once.
	public func requestAuthorization() {
		if #available(iOS 10.0, *) {
			UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
				if granted {
					self.requestDeviceToken()
				}
			}
		} else {
			let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
			UIApplication.shared.registerUserNotificationSettings(settings)
		}
	}
	
	public func requestDeviceToken() {
		#if !(arch(i386) || arch(x86_64))
			DispatchQueue.main.async {
				UIApplication.shared.registerForRemoteNotifications()
			}
		#endif
	}
}
#endif
