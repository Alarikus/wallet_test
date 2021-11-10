//
//  Wallet.swift
//  wallets
//
//  Created by Bogdan Redkin on 09.11.2021.
//

import Foundation

struct Wallet: Hashable, Codable {
    let id: String
    let walletName: String
    let balance: Double

    enum CodingKeys: String, CodingKey {
        case walletName = "wallet_name"
        case balance, id
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let balance = Double(try container.decode(String.self, forKey: .balance)) {
            self.balance = balance
        } else {
            balance = try container.decode(Double.self, forKey: .balance)
        }
        
        id = try container.decode(String.self, forKey: .id)
        walletName = try container.decode(String.self, forKey: .walletName)
    }
}

struct WalletsResponse: Codable {
    let wallets: [Wallet]
}
