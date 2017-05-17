//
//  FileHandle.swift
//  HexavilleFramework
//
//  Created by Yuki Takei on 2017/05/17.
//
//

import Foundation

extension FileHandle: TextOutputStream {
    public func write(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        self.write(data)
    }
}
