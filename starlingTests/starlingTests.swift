//
//  starlingTests.swift
//  starlingTests
//
//  Created by Сергей Бочков on 24.01.2026.
//

import XCTest
@testable import starling

final class starlingTests: XCTestCase {
    
    var sut: RoundUpService!
    
    override func setUp() {
        super.setUp()
        sut = RoundUpService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testCalculateRoundUp_Logic() {
        let transactions = [
            makeMockTransaction(minorUnits: 120),       // £1.20 -> 80p
            makeMockTransaction(minorUnits: 1000),      // £10.00 -> 0p
            makeMockTransaction(minorUnits: 595)        // £5.95 -> 5p
        ]
        
        let result = sut.calculateRoundUp(from: transactions)
        
        XCTAssertEqual(result, 85, "Сумма округления рассчитана неверно. Ожидалось 85 пенсов.")
    }
    
    private func makeMockTransaction(minorUnits: Int) -> TransactionItem {
        return TransactionItem(
            amount: CurrencyAndAmount(currency: "GBP", minorUnits: minorUnits),
            direction: .outgoing,
            status: .settled
        )
    }
}
