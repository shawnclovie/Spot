//
//  Logger.swift
//  Spot
//
//  Created by Shawn Clovie on 20/4/2018.
//  Copyright © 2018 Shawn Clovie. All rights reserved.
//

import Foundation

public struct Log {
	
	public enum Level: Int {
		case trace, debug, info, warn, error, fatal
	}
	
	public enum OutputTarget: Hashable {
		case console
		case file(URL)
	}
	
	public let level: Level
	public let tag: String
	public let time: String
	public let messages: [Any]
	
	public init(_ level: Level, tag: String, time: String = "", _ messages: [Any]) {
		self.level = level
		self.tag = tag
		self.time = time
		self.messages = messages
	}
	
	public func output(to: OutputTarget = .console) {
		let levelTag: Character
		switch level {
		case .trace:	levelTag = "T"
		case .debug:	levelTag = "D"
		case .info:		levelTag = "I"
		case .warn:		levelTag = "W"
		case .error:	levelTag = "E"
		case .fatal:	levelTag = "F"
		}
		var items: [String] = []
		items.reserveCapacity(messages.count + (time.isEmpty ? 1 : 2))
		if !time.isEmpty {
			items.append(time)
		}
		items.append("\(levelTag)/\(tag):")
		items.append(contentsOf: messages.map(String.init(reflecting:)))
		let text = items.joined(separator: " ") + "\n"
		switch to {
		case .console:
			print(text, separator: "", terminator: "")
		case .file(let path):
			let data = Data(text.utf8)
			if let handler = FileHandle(forWritingAtPath: path.path) {
				handler.seekToEndOfFile()
				handler.write(data)
				handler.closeFile()
			} else {
				try? data.write(to: path, options: .atomic)
			}
		}
	}
}

public final class Logger {
	
	public let tag: String
	public var minimumLevel: Log.Level
	public var targets: Set<Log.OutputTarget>
	
	private var isTimeEnabled = false
	private var timeFormatter: DateFormatter?
	
	public init(tag: String, for level: Log.Level = .info, to targets: [Log.OutputTarget] = [.console]) {
		self.tag = tag
		self.minimumLevel = level
		self.targets = Set(targets)
	}
	
	public func setTime(enabled: Bool, format: String = "yyyy-MM-dd HH:mm:ss", on zone: TimeZone = .current) {
		isTimeEnabled = enabled
		if format.isEmpty || !enabled {
			timeFormatter = nil
		} else {
			let fmt = DateFormatter()
			fmt.dateFormat = format
			fmt.timeZone = zone
			timeFormatter = fmt
		}
	}
	
	public func logWithFileInfo(_ level: Log.Level, _ message: Any..., file: String = #file, function: String = #function, line: Int = #line) {
		guard level.rawValue >= minimumLevel.rawValue else {
			return
		}
		log(level, messages: ["\(file.spot.lastPathComponent ?? file[...])#\(line) \(function)"] + message)
	}
	
	public func log(_ level: Log.Level, _ message: Any...) {
		log(level, messages: message)
	}
	
	public func log(_ level: Log.Level, messages: @autoclosure ()->[Any]) {
		guard level.rawValue >= minimumLevel.rawValue else {
			return
		}
		let timeText: String
		if isTimeEnabled {
			if let fmt = timeFormatter {
				timeText = fmt.string(from: Date())
			} else {
				timeText = Date().description
			}
		} else {
			timeText = ""
		}
		let log = Log(level, tag: tag, time: timeText, messages())
		for target in targets {
			log.output(to: target)
		}
	}
}
