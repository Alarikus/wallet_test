//
//  MainTableCellViewModel.swift
//  wallets
//
//  Created by Bogdan Redkin on 10.11.2021.
//

import UIKit

final class MainTableCellViewModel: ObservableObject {
    
    static let cellIdentifier = String(describing: MainTableCellViewModel.self)
    
    var description: String?
    
    var amount: String?
    
    init (wallet: Wallet) {
        description = wallet.walletName
        amount = wallet.balance.formattedDecimal
        self.objectWillChange.send()
    }
    
    init (history: History) {
        switch history.entry {
        case .incoming:
            description = "You've received payment"
            amount = history.amount.formattedDecimal + " " + history.currency
        case .outgoing:
            description = "You've cashed out to " + history.partner
            amount = "-\(history.amount.formattedDecimal) \(history.currency)"
        }
        self.objectWillChange.send()
    }
}
