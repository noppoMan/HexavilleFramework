//
//  Body.swift
//  HexavilleFramework
//
//  Created by Yuki Takei on 2017/05/20.
//
//

import Foundation

extension Body {
    public func asData() -> Data {
        switch self {
        case .buffer(let data):
            return data
        default:
            return Data()
        }
    }
}
