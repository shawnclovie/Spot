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
	
	/// Init with RGBA, each parameter should between 0...1
	public init(floatRed red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
		let maxValue = CGFloat(UInt8.max)
		self.red = UInt8(maxValue * min(1, max(0, red)))
		self.green = UInt8(maxValue * min(1, max(0, green)))
		self.blue = UInt8(maxValue * min(1, max(0, blue)))
		self.alpha = UInt8(maxValue * min(1, max(0, alpha)))
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
	
	public init(gray: UInt8, alpha: UInt8 = .max) {
		self.init(red: gray, green: gray, blue: gray, alpha: alpha)
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
	
	public var floatRed: CGFloat {CGFloat(red) / CGFloat(UInt8.max)}
	public var floatGreen: CGFloat {CGFloat(green) / CGFloat(UInt8.max)}
	public var floatBlue: CGFloat {CGFloat(blue) / CGFloat(UInt8.max)}
	public var floatAlpha: CGFloat {CGFloat(alpha) / CGFloat(UInt8.max)}

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

extension DecimalColor {
	
	public init(cgColor: CGColor) {
		if let comps = cgColor.components, comps.count >= 4 {
			let max = CGFloat(UInt8.max)
			self.init(red: UInt8(comps[0] * max), green: UInt8(comps[1] * max),
					  blue: UInt8(comps[2] * max), alpha: UInt8(comps[3] * max))
		} else {
			#if canImport(UIKit)
			let color = UIColor(cgColor: cgColor)
			#elseif canImport(AppKit)
			let color = NSColor(cgColor: cgColor) ?? .init()
			#endif
			self = .init(with: color)
		}
	}
	
	public var cgColor: CGColor {
		if let cg = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [floatRed, floatGreen, floatBlue, floatAlpha]) {
			return cg
		}
		return colorValue.cgColor
	}
}

extension DecimalColor: Equatable {
	public static func ==(l: DecimalColor, r: DecimalColor) -> Bool {
		l.red == r.red && l.green == r.green && l.blue == r.blue && l.alpha == r.alpha
	}
	
	public static var clear: DecimalColor {
		.init(gray: .min, alpha: .min)
	}
	
	public static var black: DecimalColor {
		.init(gray: .min, alpha: .max)
	}
	
	public static var white: DecimalColor {
		.init(gray: .max, alpha: .max)
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
		self.init(floatRed: r, green: g, blue: b, alpha: a)
	}
	
	public var colorValue: UIColor {
		.init(red: floatRed, green: floatGreen, blue: floatBlue, alpha: floatAlpha)
	}
}
#endif

#if canImport(AppKit)
import AppKit

extension DecimalColor {
	public init(with color: NSColor) {
		var r: CGFloat = 0
		var g: CGFloat = 0
		var b: CGFloat = 0
		var a: CGFloat = 0
		color.getRed(&r, green: &g, blue: &b, alpha: &a)
		self.init(floatRed: r, green: g, blue: b, alpha: a)
	}
	
	public var colorValue: NSColor {
		.init(red: floatRed, green: floatGreen, blue: floatBlue, alpha: floatAlpha)
	}
}
#endif
