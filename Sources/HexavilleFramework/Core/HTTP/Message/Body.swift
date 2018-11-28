//
//  Body.swift
//  Prorsum
//
//  Created by Yuki Takei on 2016/11/28.
//
//

import Foundation

public enum Body {
    case buffer(Data)
}

extension Body {
    public static var empty: Body {
        return .buffer(Data())
    }
    
    public var isEmpty: Bool {
        switch self {
        case .buffer(let buffer): return buffer.isEmpty
        default: return false
        }
    }
}

extension Body {
    public var isBuffer: Bool {
        switch self {
        case .buffer: return true
        default: return false
        }
    }
}
