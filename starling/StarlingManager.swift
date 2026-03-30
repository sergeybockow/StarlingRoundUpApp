//
//  StarlingManager.swift
//  starling
//
//  Created by Сергей Бочков on 24.01.2026.
//
//
import Foundation

enum ApiError: Error {
    case invalidUrl
    case serverError
    case decodingError
}

enum StarlingEndpoint {
    case accounts
    case transactions(account: String, category: String)
    
    private var path: String {
        switch self {
        case .accounts:
            return "/api/v2/accounts"
        case .transactions(account: let account, category: let category):
            return "/api/v2/feed/account/\(account)/category/\(category)/transactions-between"
        }
    }
    
    private var queryItems: [URLQueryItem]? {
        switch self {
        case .accounts:
            return nil
        case .transactions:
            return [
                URLQueryItem(name: "minTransactionTimestamp", value: "2026-01-01T00:00:00Z"),
                URLQueryItem(name: "maxTransactionTimestamp", value: "2026-01-31T23:59:59Z")
            ]
        }
    }
    
    func url(baseURL: String) -> URL? {
        var components = URLComponents(string: baseURL)
        components?.path = self.path
        components?.queryItems = self.queryItems
        return components?.url
    }
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
    let direction: TransactionDirection
    let status: TransactionStatus
}

struct TransactionFeedResponse: Decodable {
    let feedItems: [TransactionItem]
}

protocol StarlingManager {
    func fetchAccounts() async throws -> [Account]
    func fetchTransactions(account: String, category: String) async throws -> [TransactionItem]
}

final class StarlingManagerImpl: StarlingManager {
    let baseUrl = "https://api-sandbox.starlingbank.com"
    
    private let jsonDecoder = JSONDecoder()
    private let urlSession: URLSession
    
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    func fetchAccounts() async throws -> [Account] {
        let response: AccountHolder = try await performRequest(endpoint: .accounts)
        return response.accounts
    }
    
    func fetchTransactions(account: String, category: String) async throws -> [TransactionItem] {
        let response: TransactionFeedResponse = try await performRequest(endpoint: .transactions(account: account, category: category))
        return response.feedItems
    }
    
    private func performRequest<T: Decodable>(endpoint: StarlingEndpoint) async throws -> T {
        guard let url = endpoint.url(baseURL: baseUrl) else {
            throw ApiError.invalidUrl
        }
        
        let request = createRequest(url: url)
        
        let (data, response) = try await urlSession.data(for: request)
        try validate(response)
        
        return try jsonDecoder.decode(T.self, from: data)
    }
    
    private func createRequest(url: URL) -> URLRequest {
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

final class RoundUpService {
    func calculateRoundUp(from transactions: [TransactionItem]) -> Int {
        let filtered = transactions.filter { $0.direction == .outgoing && $0.status == .settled }
        
        return filtered.reduce(0) { sum, transaction in
            let pence = transaction.amount.minorUnits % 100
            
            let gap = pence == 0 ? 0 : (100 - pence)
            return sum + gap
        }
    }
}
