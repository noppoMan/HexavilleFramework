#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

import Foundation
import NIO

extension String {
    public var data: Data {
        return self.data(using: .utf8) ?? Data()
    }
    
    public var byteBuffer: ByteBuffer {
        var buf = ByteBufferAllocator().buffer(capacity: self.count)
        buf.write(string: self)
        return buf
    }
    
    public func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public func trimLeft(_ characterSet: CharacterSet) -> String {
        for c in reversed().enumerated() {
            let isMatch = c.element.unicodeScalars.contains { characterSet.contains($0) }
            if !isMatch {
                return String(prefix(upTo: index(endIndex, offsetBy: -c.offset)))
            }
        }
        return self
    }
    
    public func trimRight(_ characterSet: CharacterSet) -> String {
        for c in enumerated() {
            let isMatch = c.element.unicodeScalars.contains { characterSet.contains($0) }
            if !isMatch {
                return String(suffix(from: index(startIndex, offsetBy: c.offset)))
            }
        }
        return self
    }
}

extension Substring.SubSequence {
    public func trim() -> String {
        return String(self).trim()
    }
}
