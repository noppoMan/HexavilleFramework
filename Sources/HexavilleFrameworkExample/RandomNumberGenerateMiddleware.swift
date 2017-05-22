//
//  RundomNumberMiddleware.swift
//  HexavilleFramework
//
//  Created by Yuki Takei on 2017/05/23.
//
//

import Foundation
import HexavilleFramework

struct RandomNumberGenerateMiddleware: Middleware {
    func respond(to request: Request, context: ApplicationContext) throws -> Chainer {
        #if os(Linux)
            srandom(UInt32(time(nil)))
            let randomNumber = String(format: "%04d", UInt32(random() % 10000))
        #else
            let randomNumber = String(format: "%04d", Int(arc4random_uniform(9999)))
        #endif
        
        context.storage["randumNumber"] = randomNumber
        
        return .next(request)
    }
}
