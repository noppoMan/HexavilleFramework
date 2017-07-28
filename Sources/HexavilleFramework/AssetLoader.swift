//
//  AssetLoader.swift
//  HexavilleFramework
//
//  Created by Yuki Takei on 2017/07/28.
//

import Foundation

public enum AssetLoaderError: Error {
    case assetsNotFoundInCadidates([String])
    case couldNotFind(String)
}

public struct AssetLoader {
    public static let shared = AssetLoader()
    
    public var assetPathCandidates = [String]()
    
    public init() {
        let root = #file.characters
            .split(separator: "/", omittingEmptySubsequences: false)
            .dropLast(2)
            .map { String($0) }
            .joined(separator: "/")
        
        assetPathCandidates.append(contentsOf: [
            FileManager.default.currentDirectoryPath, // in lambda
            root // local development
            ])
        
        let components = root.components(separatedBy: "/.build")
        if components.count > 1 {
            assetPathCandidates.append(components[0]) // used as dependency
        }
        assetPathCandidates = assetPathCandidates.map({ "\($0)/assets" })
    }
    
    public func availableAbsolutePathForAssets() -> String? {
        for assetPath in assetPathCandidates {
            if FileManager.default.fileExists(atPath: assetPath) {
                return assetPath
            }
        }
        
        return nil
    }
    
    public func load(fileInAssets path: String) throws -> Data {
        guard let assetPath = availableAbsolutePathForAssets() else {
            throw AssetLoaderError.assetsNotFoundInCadidates(assetPathCandidates)
        }
        
        return try Data(contentsOf: URL(string: "file://\(assetPath)\(path)")!)
    }
}
