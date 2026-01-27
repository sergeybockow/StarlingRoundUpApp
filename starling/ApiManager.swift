//
//  ApiManager.swift
//  starling
//
//  Created by Сергей Бочков on 24.01.2026.
//

//  base url
//  account прием данных
//  class с логикой и декодингом
//  enum error
//  URLSession
//  fetchAccounts async await
//  guard url + urlString +
//  URLRequest
//  addValue
//  (data, response)
//  decode[Account]

import Foundation

struct Account: Decodable {
    let accountUid: String
    let defaultCategory: String
    let currency: String
}

struct AccountsResponse: Decodable {
    let accounts: [Account]
}

struct CurrencyAndAmount: Decodable {
    let currency: String
    let minorUnits: Int
}

struct Transaction: Decodable {
    let feedItemUid: String
    let amount: CurrencyAndAmount
    let direction: TransactionDirection     // CustomerDetails.swift
    let status: TransactionStatus           // CustomerDetails.swift
}

struct FeedResponse: Decodable {
    let feedItems: [Transaction]
}

enum AccountError: Error {
    case unknown
    case invalidURL
    case httpError
    case nonUid
}

final class AccountManager {
    private let baseUrl = "https://api-sandbox.starlingbank.com"
    private let urlSession: URLSession
    
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    private lazy var jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()
    
    func fetchAccounts() async throws -> [Account] {
        let urlString = baseUrl + "/api/v2/accounts"
        
        guard let request = createRequest(urlString: urlString) else {
            throw AccountError.invalidURL
        }
        
        let (data, response) = try await urlSession.data(for: request)
        try validate(response)
        
        let decodedResponse = try jsonDecoder.decode(AccountsResponse.self, from: data)
        
        return decodedResponse.accounts
    }
    
    func fetchTransactions(account: String, category: String) async throws -> [Transaction] {
        let urlString = baseUrl + "/api/v2/feed/account/\(account)/category/\(category)/transactions-between"
        
        let now = Date()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        
        let minDate = dateFormatter.string(from: sevenDaysAgo)
        let maxDate = dateFormatter.string(from: now)
        
        guard var components = URLComponents(string: urlString) else {
            throw AccountError.invalidURL
        }
        
        components.queryItems = [
            URLQueryItem(name: "minTransactionTimestamp", value: minDate),
            URLQueryItem(name: "maxTransactionTimestamp", value: maxDate)
        ]
        
        guard let url = components.url,
              let request = createRequest(urlString: url.absoluteString) else {
            throw AccountError.invalidURL
        }
        
        let (data, response) = try await urlSession.data(for: request)
        
        if let httpRes = response as? HTTPURLResponse {
            print("🌐 Статус код сервера: \(httpRes.statusCode) | Found: \(data.count) bytes")
        }
        
        try validate(response)
        
        let decoded = try jsonDecoder.decode(FeedResponse.self, from: data)
        return decoded.feedItems
    }
    
    func calculateRoundUp(from transactions: [Transaction]) -> Int {
        let outgoins = transactions.filter { $0.direction == .outgoing && $0.status == .settled}
        let totalRoundUp = outgoins.reduce(0) { accumulated, transaction in
            let pence = transaction.amount.minorUnits % 100
            
            if pence > 0 {
                let gap = 100 - pence
                return accumulated + gap
            }
            return accumulated
        }
        return totalRoundUp
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
            throw AccountError.httpError
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            print("🌐 Server error: \(httpResponse.statusCode)")
            throw AccountError.httpError
        }
    }
}
