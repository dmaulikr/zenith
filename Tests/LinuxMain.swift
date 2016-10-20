import XCTest
@testable import WorldTests
@testable import UITests

XCTMain([
    testCase(SerializationTests.allTests),
    testCase(CommandTests.allTests),
])
