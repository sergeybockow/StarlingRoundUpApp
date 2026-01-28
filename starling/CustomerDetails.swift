//
//  CustomerDetails.swift
//  starling
//
//  Created by Сергей Бочков on 24.01.2026.
//

enum CustomerDetails {
    static let accessToken = "YOUR_TOKEN_HERE"      // Вставить токен сюда
    static let fieldContentType = "application/json"
    static let fieldAccept = "application/json"
}

enum TransactionDirection: String, Decodable {
    case outgoing = "OUT"
    case incoming = "IN"
}

enum TransactionStatus: String, Decodable {
    case settled = "SETTLED"
    case pending = "PENDING"
    case declined = "DECLINED"
}
