//
//  Logger.swift
//  HexavilleFramework
//
//  Created by Yuki Takei on 2017/05/22.
//
//

import Foundation

#if os(OSX)
    import Darwin.C
#else
    import Glibc
#endif

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
        if let _ = ProcessInfo.processInfo.environment["LAMBDA_TASK_ROOT"] {
            fputs("[\(levelString)] \(message)", stderr)
        } else {
            print("[\(levelString)] \(message)")
        }
    }
}
