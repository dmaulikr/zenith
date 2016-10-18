import XCTest
@testable import WorldTests

XCTMain([
    testCase(SerializationTests.allTests),
    testCase(UITests.allTests),
])
