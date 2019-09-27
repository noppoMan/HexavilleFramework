//
//  Logger.swift
//  HexavilleFramework
//
//  Created by Yuki Takei on 2017/05/22.
//
//

import Foundation

public enum LogLevel {
    case info
    case debug
    case warning
    case error
    case fatal
}

public protocol Logger {
    func log(level: LogLevel, message: String)
}

public struct StandardOutputLogger: Logger {
    public func log(level: LogLevel = .info, message: String) {
        let levelString = "\(level)".uppercased()
        print("[\(levelString)] \(message)")
    }
}
