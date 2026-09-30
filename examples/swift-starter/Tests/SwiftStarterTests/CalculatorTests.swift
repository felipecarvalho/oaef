import XCTest
@testable import SwiftStarter

final class CalculatorTests: XCTestCase {
    func testAddCalculatesSumCorrectly() {
        let calculator = Calculator()
        XCTAssertEqual(calculator.add(firstNumber: 2, secondNumber: 3), 5)
    }

    func testMultiplyCalculatesProductCorrectly() {
        let calculator = Calculator()
        XCTAssertEqual(calculator.multiply(firstNumber: 3, secondNumber: 4), 12)
    }
}
