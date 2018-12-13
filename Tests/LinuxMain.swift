import XCTest
@testable import HexavilleFrameworkTests

XCTMain([
    testCase(RouterTests.allTests),
    testCase(HostResolverTests.allTests),
    testCase(HexavilleFrameworkTests.allTests),
])
