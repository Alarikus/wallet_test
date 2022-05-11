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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let amount = Double(try container.decode(String.self, forKey: .amount)) {
            self.amount = amount
        } else {
            self.amount = try container.decode(Double.self, forKey: .amount)
        }
        
        self.id = try container.decode(String.self, forKey: .id)
        self.entry = try container.decode(Entry.self, forKey: .entry)
        self.currency = try container.decode(String.self, forKey: .currency)
        self.partner = try container.decode(String.self, forKey: .partner)
        self.date = try container.decode(Date.self, forKey: .date)
    }

}

struct HistoryResponse: Codable {
    let data: [History]
    let pageCount: Int
}
