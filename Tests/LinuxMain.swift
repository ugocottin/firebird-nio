import XCTest

import firebird_nioTests

var tests = [XCTestCaseEntry]()
tests += firebird_nioTests.allTests()
XCTMain(tests)
