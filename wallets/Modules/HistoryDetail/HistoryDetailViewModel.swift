//
//  HistoryViewModel.swift
//  wallets
//
//  Created by Bogdan Redkin on 09.11.2021.
//

import Foundation
import UIKit
import Combine

final class HistoryDetailViewModel {
    
    @Published private(set) var title: String!
    @Published private(set) var details: [String: String]!
    
    private var bindings = Set<AnyCancellable>()
        
    private let selectedHistory: History
        
    init(_ selectedHistory: History) {
        self.selectedHistory = selectedHistory
    }

    func onLoadView() {
        switch selectedHistory.entry {
        case .incoming:
            title = "You've received payment"
            details = [
                "Sender:": selectedHistory.partner,
                "Amount:": selectedHistory.amount.formattedDecimal + " " + selectedHistory.currency,
                "Date:": selectedHistory.date.formatted()
            ]
        case .outgoing:
            title = "You've cashed out to " + selectedHistory.partner
            details = [
                "Recipient:": selectedHistory.partner,
                "Amount:": "-\(selectedHistory.amount.formattedDecimal) \(selectedHistory.currency)",
                "Date:": selectedHistory.date.formatted()
            ]
        }
    }
    
}
