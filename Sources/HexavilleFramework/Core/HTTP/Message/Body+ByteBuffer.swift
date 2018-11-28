//
//  Body.swift
//  HexavilleFramework
//
//  Created by Yuki Takei on 2017/05/20.
//
//

import Foundation
import NIO

extension Body {
    public func asByteBuffer() -> ByteBuffer {
        switch self {
        case .buffer(let data):
            var buf = ByteBufferAllocator().buffer(capacity: data.count)
            buf.write(bytes: data)
            return buf
        default:
            return ByteBufferAllocator().buffer(capacity: 0)
        }
    }
}
