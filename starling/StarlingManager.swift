//
//  ApiManager.swift
//  starling
//
//  Created by Сергей Бочков on 24.01.2026.
//

import Foundation

enum ApiError: Error {
    case invalidUrl
    case serverError
    case decodingError
}

struct Account: Decodable {
    let accountUid: String
    let defaultCategory: String
}

struct AccountHolder: Decodable {
    let accounts: [Account]
}

struct CurrencyAndAmount: Decodable {
    let currency: String
    let minorUnits: Int
}

struct TransactionItem: Decodable {
    let amount: CurrencyAndAmount
    let direction: TransactionDirection     // CustomerDetails.swift
    let status: TransactionStatus           // CustomerDetails.swift
}

struct TransactionFeedResponse: Decodable {
    let feedItems: [TransactionItem]
}

final class StarlingManager {
    let baseUrl = "https://api-sandbox.starlingbank.com"
    
    private var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        return decoder
    }
    
    let urlSession: URLSession
    
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    func fetchAccounts() async throws -> [Account] {
        let urlString = baseUrl + "/api/v2/accounts"
        
        guard let request = createRequest(urlString: urlString) else {
            throw ApiError.invalidUrl
        }
        
        let (data, response) = try await urlSession.data(for: request)
        
        try validate(response)
        
        let decodeResponse = try jsonDecoder.decode(AccountHolder.self, from: data)
        
        return decodeResponse.accounts
    }
    
    func fetchTransactions(account: String, category: String) async throws -> [TransactionItem] {
        let urlString = baseUrl + "/api/v2/feed/account/\(account)/category/\(category)/transactions-between?minTransactionTimestamp=2026-01-01T00:00:00Z&maxTransactionTimestamp=2026-01-31T23:59:59Z"
        
        guard let request = createRequest(urlString: urlString) else {
            throw ApiError.invalidUrl
        }
        
        let (data, response) = try await urlSession.data(for: request)
        
        try validate(response)
        
        let decode = try jsonDecoder.decode(TransactionFeedResponse.self, from: data)
        
        return decode.feedItems
    }
    
    private func createRequest(urlString: String) -> URLRequest? {
        guard let url = URL(string: urlString) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(CustomerDetails.accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("\(CustomerDetails.fieldAccept)", forHTTPHeaderField: "Accept")
        request.addValue("Sergey", forHTTPHeaderField: "User-Agent")
        return request
    }
    
    private func validate(_ response: URLResponse?) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.serverError
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            print("🌐 Server error: \(httpResponse.statusCode)")
            throw ApiError.serverError
        }
    }
}

// MARK: - Business Logic

extension StarlingManager {
    func calculateRoundUp(from transactions: [TransactionItem]) -> Int {
        let filtered = transactions.filter { $0.direction == .outgoing && $0.status == .settled }
        
        let totalRoundUp = filtered.reduce(0) { sum, transactions in
            let pence = transactions.amount.minorUnits % 100
            
            if pence > 0 {
                let gap = 100 - pence
                return sum + gap
            }
            return sum
        }
        return totalRoundUp
    }
}
