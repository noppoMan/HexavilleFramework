//
//  Body+Data.swift
//
//  Created by Yuki Takei on 2018/11/28.
//

import Foundation

extension Body {
    public func asData() -> Data {
        switch self {
        case .buffer(let data):
            return data
        }
    }
}
