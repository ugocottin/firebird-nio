import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(firebird_nioTests.allTests),
    ]
}
#endif
