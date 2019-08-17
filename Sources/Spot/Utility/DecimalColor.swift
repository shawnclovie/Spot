//
//  DecimalColor.swift
//  Spot
//
//  Created by Shawn Clovie on 22/8/2018.
//  Copyright © 2018 Shawn Clovie. All rights reserved.
//

import Foundation
import CoreGraphics

/// Convert HSV(HSB) color to RGB
///
/// - Parameters:
///   - h: Hue (0~1)
///   - s: Saturation (0~1)
///   - v: Brightness (0~1)
/// - Returns: RGB values (0~1)
private func hsv2rgb(h: Double, s: Double, v: Double) -> (r: Double, g: Double, b: Double) {
	let h = (h >= 1 || h < 0 ? 0 : h) * 360
	let sector = Int(h / 60) % 6
	let f = h / 60 - Double(sector)
	let p = v * (1 - s)
	let q = v * (1 - s * f)
	let t = v * (1 - s * (1 - f))
	switch(sector) {
	case 0:		return (v, t, p)
	case 1:		return (q, v, p)
	case 2:		return (p, v, t)
	case 3:		return (p, q, v)
	case 4:		return (t, p, v)
	default:	return (v, p, q)
	}
}

public struct DecimalColor {
	public var red: UInt8
	public var green: UInt8
	public var blue: UInt8
	public var alpha: UInt8
	
	public init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
		self.red = red
		self.green = green
		self.blue = blue
		self.alpha = alpha
	}
	
	/// Create color from number mixed RGB and alpha
	///
	/// - Parameters:
	///   - rgb: Mixed RGB color, e.g. 0xFF0000
	///   - alpha: Alpha
	public init(rgb: UInt32, alpha: UInt8 = .max) {
		self.init(red: UInt8((rgb & 0xFF0000) >> 16),
				  green: UInt8((rgb & 0xFF00) >> 8),
				  blue: UInt8(rgb & 0xFF),
				  alpha: alpha)
	}
	
	/// Create color with HSB/HSV and alpha
	///
	/// - Parameters:
	///   - hue: 0~1
	///   - saturation: 0~1
	///   - brightness: 0~1
	///   - alpha: 0~1
	public init(hue: Double, saturation: Double, brightness: Double, alpha: Double) {
		let (r, g, b) = hsv2rgb(h: hue, s: saturation, v: brightness)
		let max = Double(UInt8.max)
		self.init(red: UInt8(r * max), green: UInt8(g * max),
				  blue: UInt8(b * max), alpha: UInt8(alpha * max))
	}
	
	/// Scan color from HEX string
	/// - Parameter hex: Color string with prefix #
	public init?(hexARGB hex: String) {
		let len = hex.lengthOfBytes(using: .utf8)
		guard len > 1 else {return nil}
		var color: UInt32 = 0
		let scanner = Scanner(string: hex)
		scanner.scanLocation = 1
		scanner.scanHexInt32(&color)
		self.init(rgb: color, alpha: len >= 9 ? UInt8((color & 0xFF000000) >> 24) : .max)
	}
	
	public var hexString: String {
		let rgb = String(format: "%02lX%02lX%02lX", red, green, blue)
		return "#" + (alpha == .max ? rgb : String(format: "%02lX%@", alpha, rgb))
	}
	
	public func withAlphaComponent(_ alpha: UInt8) -> DecimalColor {
		var c = self
		c.alpha = alpha
		return c
	}
}

extension DecimalColor: Equatable {
	public static func ==(l: DecimalColor, r: DecimalColor) -> Bool {
		l.red == r.red && l.green == r.green && l.blue == r.blue && l.alpha == r.alpha
	}
	
	public static var clear: DecimalColor {
		.init(rgb: 0x000000, alpha: .min)
	}
	
	public static var black: DecimalColor {
		.init(rgb: 0x000000, alpha: .max)
	}
	
	public static var white: DecimalColor {
		.init(rgb: 0xffffff, alpha: .max)
	}
}

#if canImport(UIKit)
import UIKit

extension DecimalColor {
	
	public init(with color: UIColor) {
		var r: CGFloat = 0
		var g: CGFloat = 0
		var b: CGFloat = 0
		var a: CGFloat = 0
		color.getRed(&r, green: &g, blue: &b, alpha: &a)
		let max = CGFloat(UInt8.max)
		self.init(red: UInt8(r * max), green: UInt8(g * max),
				  blue: UInt8(b * max), alpha: UInt8(a * max))
	}
	
	public var colorValue: UIColor {
		let max = CGFloat(UInt8.max)
		return UIColor(red: CGFloat(red) / max, green: CGFloat(green) / max,
					 blue: CGFloat(blue) / max, alpha: CGFloat(alpha) / max)
	}
}
#endif
