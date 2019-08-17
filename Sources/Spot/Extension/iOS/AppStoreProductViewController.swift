//
//  AppStoreProductViewController.swift
//  Spot
//
//  Created by Shawn Clovie on 16/02/2017.
//  Copyright © 2017 Shawn Clovie. All rights reserved.
//

#if canImport(UIKit)
import StoreKit
import UIKit

open class AppStoreProductViewController: SKStoreProductViewController, SKStoreProductViewControllerDelegate {
	
	public var finishedHandler: ((AppStoreProductViewController)->Void)?
	
	/// Open app page in store
	open func load(iTunesID id: String, handler: @escaping (SKStoreProductViewController, Error?)->Void, finished: ((UIViewController)->Void)?) {
		delegate = self
		finishedHandler = finished
		loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: id]) { loaded, error in
			handler(self, error ?? (loaded ? nil : AttributedError(.itemNotFound, object: id)))
		}
	}
	
	open func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
		finishedHandler?(self)
	}
}
#endif
