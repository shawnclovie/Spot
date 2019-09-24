//
//  SpotTests.swift
//  SpotTests
//
//  Created by Shawn Clovie on 17/8/2019.
//  Copyright © 2019 Spotlit.club. All rights reserved.
//

#if canImport(MobileCoreServices)
import MobileCoreServices
#else
import CoreServices
#endif
import XCTest
@testable import Spot

private let zipContent = """
abc
opq
123
\(Date().timeIntervalSince1970 * 1000)
"""

let logger = Logger(tag: "\(SpotTests.self)", for: .trace)

class SpotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
	
	func testBundle() {
		let bundle = Bundle.main
		print("path:", bundle.bundlePath,
			  "\nid:", bundle.spot.identify,
			  "\nsupportedLanguages:", bundle.localizations,
			  "\npref languages:", bundle.preferredLocalizations)
		print(bundle.infoDictionary ?? [:])
	}
	
	func testLocalization() {
		print(Localization.shared.preferredLanguage as Any)
		print(Localization.shared.localizedString(key: "ok"))
	}
	
	// MARK: - Extensions
	
	func testCollectionExtension() {
		let dict: [AnyHashable: Any] = [
			"a": ["aa": 10, "bb": 11],
			"b": [1, 2, 3],
			"c": 100,
		]
		XCTAssert(dict.spot_value(keys: ["a", "aa"]) as? Int == 10)
		XCTAssertNotNil(dict.spot_value(keys: ["b"]))
		XCTAssert(dict.spot_value("c") as? Int == 100)
		
		let array: [Int] = [1, 2, 3]
		XCTAssertNil(array.spot_value(at: 10))
	}
	
	func testStringExtensions() {
		XCTAssertEqual("1".spot.md5, "c4ca4238a0b923820dcc509a6f75849b")
		XCTAssertEqual("a".spot.md5HashCode, 2933798017325973772)
		XCTAssertEqual(String.spot(queryString: [("a", 1), ("b", 2)]), "a=1&b=2")
		XCTAssertEqual("1.txt".spot.pathExtension, "txt")
		XCTAssertEqual("foo/bar".spot.lastPathComponent, "bar")
		XCTAssertEqual("abcd".spot.substring(from: 0, to: 2), "ab")
		XCTAssertEqual("abcd".spot.substring(from: 1, to: -1), "bcd")
		XCTAssertEqual("abcd".spot.substring(from: -3, to: -1), "cd")
		XCTAssertEqual("abcd".spot.char(at: 2), "c")
		XCTAssertEqual("abcd".spot.char(at: -2), nil)
		XCTAssertEqual("<b>&'\"".spot.encodedHTMLSpecialCharacters, "&lt;b&gt;&amp;&apos;&quot;")
		XCTAssertEqual("a=1&b=2".spot.parsedQueryString, ["a": "1", "b": "2"])
		XCTAssertEqual("True".spot.boolValue, true)
		XCTAssertEqual("true".spot.boolValue, true)
		XCTAssertEqual("100".spot.boolValue, true)
		XCTAssertEqual("yes".spot.boolValue, true)
		XCTAssertEqual(" true".spot.boolValue, false)
	}
	
	func testDataExtensions() {
		XCTAssertEqual("ab".data(using: .utf8)!.spot.hexString, "6162")
	}
	
	// MARK: -
	
	func testDecimalColor() {
		#if canImport(UIKit)
		XCTAssert(DecimalColor.clear == .init(with: .clear))
		XCTAssert(DecimalColor.black == .init(with: .black))
		XCTAssert(DecimalColor.white == .init(with: .white))
		XCTAssert(DecimalColor(cgColor: UIColor.red.cgColor).red == UInt8.max)
		#endif
		XCTAssert(DecimalColor(rgb: 0xff0000) == .init(with: .red))
		XCTAssert(DecimalColor(hexARGB: "#ffff0000")! == .init(with: .red))
		XCTAssert(DecimalColor(rgb: 0xff0000) == .init(with: .init(red: 1, green: 0, blue: 0, alpha: 1)))
		XCTAssert(DecimalColor(floatRed: 2, green: 0, blue: 0, alpha: 1).red == .max)
		var values: [DecimalColor] = [
			.clear,
			.init(rgb: 0xfd020f, alpha: 60),
			DecimalColor(hexARGB: "#ff0000")!,
			DecimalColor(hexARGB: "#f2002401")!,
			DecimalColor(hue: 0.2, saturation: 0.02, brightness: 0.76, alpha: 0.9),
			]
		#if canImport(UIKit)
		values.append(DecimalColor(with: .purple).withAlphaComponent(120))
		values.append(.init(with: .yellow))
		#endif
		values.forEach{
			print($0.hexString, $0, terminator: "")
			#if canImport(UIKit)
			print($0.colorValue, terminator: "")
			#endif
			print()
		}
	}
	
	func testLogger() {
		let path = URL.spot_cachesPath.appendingPathComponent("log.txt")
		try? FileManager.default.removeItem(at: path)
		logger.logWithFileInfo(.info, path)
		NSLog("NSLog: %@", "something")
		[Logger(tag: "Test", for: .info), Logger(tag: "TestFile", for: .info, to: [.file(path)])]
			.forEach{ logger in
				logger.log(.info, "without time")
				logger.setTime(enabled: true)
				logger.log(.info, "info", "some info message")
				logger.log(.error, AttributedError(.operationFailed, object: UserDefaults.standard, userInfo: ["path": "/foo/bar"]), "other error message")
				logger.logWithFileInfo(.info, "info")
				logger.logWithFileInfo(.warn, "warn")
				logger.setTime(enabled: true, format: "yyyy-MM-dd HH:mm:ss", on: TimeZone(secondsFromGMT: 0)!)
				logger.log(.info, messages: ["info", "in array"])
				logger.log(.error, messages: ["error", "in array"])
				logger.logWithFileInfo(.info, "info")
				logger.logWithFileInfo(.warn, "warn")
		}
	}
	
	func testMIMEType() {
		var expections: [XCTestExpectation] = [XCTestExpectation()]
		logger.logWithFileInfo(.debug, URLTask.mimeType(filename: "abc.jpg"))
		logger.logWithFileInfo(.debug, URLTask.mimeType(filename: "abc.ppt"))
		DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
			logger.logWithFileInfo(.debug, URLTask.mimeType(filename: "abc.m"))
			expections[0].fulfill()
		}
		wait(for: expections, timeout: 10)
	}
	
	func testQueryString() {
		let params: [AnyHashable: Any] = ["path": "abc.jpg", "locale": ["en_US"]]
		print(String.spot(queryString: params, encode: true))
	}
	
	func testURLParameter() {
		var p1 = URLParameters()
		p1["a"] = 1
		p1["b"] = 2
		let kp1 = String.spot(queryString: p1.keyValuePairs)
		let kpt = String.spot(queryString: URLParameters(["b": 2, "a": 1]).keyValuePairs)
		XCTAssert(kp1 == kpt, "\(kp1) != \(kpt)")
		var p2 = URLParameters(["b": 3])
		p2.append("a", 2)
		p1.append(p2, allowRepeatKey: true)
		XCTAssert(p1.values(key: "a") as? [Int] == [1, 2])
		p1.set("a", as: [3, 4])
		XCTAssert(p1.values(key: "a") as? [Int] == [3, 4])
	}
	
	func testURLTask() {
		let conn = URLConnection()
		var exps: [XCTestExpectation] = []
		do {
			let exp = XCTestExpectation()
			exps.append(exp)
			let task = URLTask(.spot(.post, URL(string: "http://localhost:8080/social/activities")!))
			task.set(parameters: URLParameters([
				"app": "memo_test", "limit": 20, "type": "ex_event", "events": "s", "from": "all"
				], headers: ["Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdXRoX2lkIjoiOTE1MjAyNjY1Nzc5MDQwMjU3IiwiYXV0aF90eXBlIjoiZW0iLCJ1c2VyX2lkIjoiOTE1MjAyNjY1Nzc5MDQwMjU2In0.uJ3VrGvtlBcJumqEfSVeNKgullweVEAbF1E7DcsIFlU"]))
			task.request(with: conn) { task, result in
				if case .success(let data) = result {
					print(String(data: data, encoding: .utf8) as Any)
				}
				exp.fulfill()
			}
		}
		do {
			let exp = XCTestExpectation()
			exps.append(exp)
			URLTask(.spot(.get, URL(string: "https://media.riffsy.com/images/5ce76a640011902a79b484da92b0d7db/raw")!)).request(with: conn) { task, result in
				logger.logWithFileInfo(.debug, result)
				if NetworkObserver.withWiFi!.currentStatus == .notReachable {
					XCTAssertNil(try? result.get())
				} else {
					XCTAssertNotNil(try? result.get())
				}
				exp.fulfill()
			}
		}
		do {
			let exp = XCTestExpectation()
			exps.append(exp)
			URLTask(.spot(.get, URL(string: "http://dailymemo.spotlit.club.s3-website-us-east-1.amazonaws.com/files/user-avatar/25141851115753472_1531137248.jpg")!)).request { task, result in
				XCTAssert(task.respondStatusCode == 404)
				exp.fulfill()
			}
		}
		wait(for: exps, timeout: 10)
	}

	class AllowAllConnection: URLConnection {
		static let shared = AllowAllConnection()
		
		func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
			logger.logWithFileInfo(.trace, challenge)
			completionHandler(.useCredential, challenge.protectionSpace.serverTrust.map(URLCredential.init(trust:)))
		}
	}
	
	func testURLTaskUntrustCA() {
		let url = URL(string: "https://image.haosou.com/j?q=acg&src=srp&sn=0&pn=24")!
		let exp = XCTestExpectation()
		URLTask(.spot(.get, url)).request(with: AllowAllConnection.shared) { (task, result) in
			do {
				let data = try result.get()
				print(String(data: data, encoding: .utf8)!)
			} catch {
				XCTFail("\(error)")
			}
			exp.fulfill()
		}
		wait(for: [exp], timeout: 5)
	}
	
	func testVersion() {
		let text = "[2.5.9]"
		let v1 = Version("2.5.9")
		XCTAssertEqual(v1, Version(text.dropFirst().dropLast()))
		XCTAssertEqual(v1, Version(2, 5, 9, 0))
		XCTAssert(v1 > Version(2, 5))
		XCTAssert(v1 < Version(3))
	}
	
	func testDrawAndEncode() {
		let image: CGImage? = CGContext.spot(width: 100, height: 100) { ctx in
			ctx.setFillColor(DecimalColor(rgb: 0xFF0000).cgColor)
			ctx.fill(CGRect(x: 20, y: 20, width: 35, height: 60))
			ctx.setStrokeColor(DecimalColor(gray: 0).cgColor)
			ctx.move(to: CGPoint(x: 10, y: 10))
			ctx.addLine(to: CGPoint(x: 50, y: 50))
			return ctx.makeImage()
		}
		XCTAssertNotNil(image)
		XCTAssertTrue(image!.width == 100)
		let basepath = URL.spot_cachesPath
		logger.log(.info, basepath)
		for (ext, enc) in ["jpg": .jpeg(quality: 0.95), "png": .png] as [String: ImageEncoding] {
			let data = image!.spot.encode(as: enc, orientation: .up)
			XCTAssertNotNil(data)
			try! data!.write(to: basepath.appendingPathComponent("drawn.\(ext)"))
		}
	}
	
	func testZip() {
		do {
			let dataSRC = zipContent.data(using: .utf8)!
			let dataDEF = try dataSRC.spot.deflated()
			let dataINF = try dataDEF.spot.inflated()
			let dec = String(data: dataINF, encoding: .utf8)
			logger.logWithFileInfo(.debug, "deflate and then inflated:", dec ?? "!! encoding error")
			XCTAssertEqual(zipContent, dec)
		} catch {
			XCTFail("\(error)")
		}
	}
	
	func testCryptor() {
		guard let randomData = SymmetricCryptor.randomData(of: 50) else {
			XCTFail()
			return
		}
		print("randomData:", randomData.map {$0})
		let key = "12341234123412341234123412341234"
		let cryptor = SymmetricCryptor(algorithm: .aes256)
		do {
			let crypted = try cryptor.crypt(randomData, key: key)
			let decrypted = try cryptor.decrypt(crypted, key: key)
			XCTAssert(decrypted == randomData)
		} catch {
			XCTFail("\(error)")
		}
		do {
			let source = "akl;sfjdas;f".data(using: .utf8)!
			let crypted = try cryptor.crypt(source, key: key)
			let decrypted = try cryptor.decrypt(crypted, key: key)
			XCTAssert(decrypted == source)
		} catch {
			XCTFail("\(error)")
		}
	}
	
	func makeCGImage(size: CGSize, color: CGColor, closure: ((CGContext)->Void)? = nil) -> CGImage? {
		CGContext.spot(width: Int(size.width), height: Int(size.height), invoking: { ctx -> CGImage? in
			ctx.setFillColor(color)
			ctx.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height * 0.75))
			closure?(ctx)
			return ctx.makeImage()
		})
	}
	
	func testImageSource() {
		let size = CGSize(width: 45, height: 25)
		let image = makeCGImage(size: size, color: DecimalColor(rgb: 0x00FF00).cgColor)
		guard let data = image?.spot.encode(as: .png, orientation: nil) else {
			XCTFail()
			return
		}
		guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
			XCTFail()
			return
		}
		XCTAssert(source.spot.type == kUTTypePNG)
		let newSize = source.spot.size
		XCTAssert(newSize == size, "\(newSize)")
		guard let newImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
			XCTFail()
			return
		}
		guard let newData = newImage.spot.encode(as: .png, orientation: nil) else {
			XCTFail()
			return
		}
		XCTAssert(data == newData)
	}
	
	func testResizeCGImage() {
		let size = CGSize(width: 34, height: 232)
		let image = makeCGImage(size: size, color: DecimalColor(rgb: 0x0000FF).cgColor) {
			$0.setFillColor(DecimalColor(rgb: 0xFF0000).cgColor)
			$0.fill(CGRect(x: 5, y: 5, width: 10, height: 20))
		}
		let pathSRC = URL.spot_cachesPath.appendingPathComponent("resize_src.png")
		try! image!.spot.encode(as: .png, orientation: nil)!.write(to: pathSRC)
		guard let newImage = image!.spot.resizingImage(to: size, scale: 1.5, alpha: .noneSkipLast) else {
			XCTFail()
			return
		}
		let pathTAR = URL.spot_cachesPath.appendingPathComponent("resize_tar.png")
		try! newImage.spot.encode(as: .png, orientation: nil)!.write(to: pathTAR)
		print("resized image at", pathTAR)
	}
	
	func testKVO() {
		let obj = NSMutableParagraphStyle()
		do {
			obj.lineSpacing = 1
			let observer = KeyValueObserver(object: obj, keyPath: \.lineSpacing) { (obj, change) in
				print("value changed:", obj, change)
			}
			print(observer)
			obj.lineSpacing = 2
			observer.invalidate()
			obj.lineSpacing = 3
		}
		obj.lineSpacing = 4
		print("done")
	}
	
	func testNotificationObserver() {
		let name = Notification.Name("TestNotification")
		let name2 = Notification.Name("TN2")
		do {
			let ob1 = NotificationObserver()
			ob1.observe(name) {
				print("ob1[\(name)]", $0)
			}
			let ob2 = NotificationObserver(by: .default, shouldRemoveObserversOnDeinit: false)
			ob2.observe(name) { (note) in
				print("ob2[\(name)]", note)
			}
			ob2.observe(name2) {print("ob2[\(name2)]", $0)}
			NotificationCenter.default.post(name: name, object: "in pool")
		}
		
		NotificationCenter.default.post(name: name, object: "out pool")
		NotificationCenter.default.post(name: name2, object: "out pool")
	}
	
	let obOfVoid = EventObservable<Void>()
	let obOfText = EventObservable<String>()
	let obOfFile = EventObservable<(URL, Int64)>()
	
	class A {
		init() {}
		deinit {
			print("A#deinit")
		}
		func event(_ a: String) {
			print("A#event\(a)")
		}
	}
	
	func testEventObserver() {
		_ = obOfVoid.subscribe({
			print("publisherOfVoid event:", $0)
		})
		_ = obOfVoid.subscribe(weakTarget: self, action: #selector(voidEvent))
		obOfVoid.dispatch(())
		
		_ = obOfText.subscribe(weakTarget: self, action: #selector(textEvent))
		let ob1 = obOfText.subscribe({
			print($0)
		})
		obOfText.dispatch("S1")
		obOfText.invalidate(target: self)
		ob1.invalidate()
		obOfText.dispatch("S2")
		
		let ob2 = obOfFile.subscribe({
			print($0)
		})
		obOfFile.dispatch((URL(fileURLWithPath: "/"), 20))
		ob2.invalidate()
		obOfFile.dispatch((URL(fileURLWithPath: "/dev"), 50))
	}
	
	@objc private func voidEvent() {
		logger.logWithFileInfo(.trace, "void")
	}
	
	@objc private func textEvent(_ a: String) {
		logger.logWithFileInfo(.trace, a)
	}
	
	func testAnyTo() {
		let m: [AnyHashable: Any] = [
			"d": 1.0, "i": 1, "b": true,
			"si": "1", "sd": "1.0",
			"sy": "yes", "st": "true",
		]
		XCTAssertEqual(Int.max, AnyToInt(Int64.max))
		XCTAssertEqual(1, AnyToInt(1.1))
		XCTAssertEqual(1, AnyToInt(m["si"]))
		XCTAssertEqual(1, AnyToInt(m["b"]))
		XCTAssertEqual(0, AnyToInt(false))
		XCTAssertEqual(nil, AnyToInt(""))
		XCTAssertNotEqual(1, AnyToInt(nil))
		XCTAssertEqual(1.0, AnyToDouble(m["i"]))
		XCTAssertEqual(1.0, AnyToDouble(m["sd"]))
		XCTAssertEqual(1.0, AnyToDouble(m["b"]))
		XCTAssertEqual(0, AnyToDouble(false))
		XCTAssertEqual(nil, AnyToDouble(""))
		XCTAssertEqual(true, AnyToBool(m["i"]))
		XCTAssertEqual(true, AnyToBool(m["d"]))
		XCTAssertEqual(true, AnyToBool(m["sy"]))
		XCTAssertEqual(true, AnyToBool(m["st"]))
		XCTAssertEqual(nil, AnyToBool(nil))
		XCTAssertEqual(false, AnyToBool(0))
		XCTAssertEqual(nil, AnyToBool(""))
		
		XCTAssertEqual(9223372036854775807, AnyToInt64("9223372036854775807"))
		XCTAssertEqual(1, AnyToInt64(1))
		XCTAssertEqual(1, AnyToInt64(1.1))
	}
}
