//
//  History.swift
//  wallets
//
//  Created by Bogdan Redkin on 09.11.2021.
//

import Foundation

struct History: Hashable, Codable {
    
    let id: String
    let entry: Entry
    let amount: Double
    let currency: String
    let partner: String
    let date: Date
    
    enum Entry: String, Codable {
        case incoming
        case outgoing
    }
}

struct HistoryResponse: Codable {
    let data: [History]
    let pageCount: Int
}
