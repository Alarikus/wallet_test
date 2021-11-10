//
//  ViewModelProvider.swift
//  wallets
//
//  Created by Bogdan Redkin on 09.11.2021.
//

import Foundation

protocol ViewModelProvider {
    
    func mainViewModel() -> MainViewModel
    
    func historyViewModel(selectedHistory: History) -> HistoryDetailViewModel
    
    func mainCellViewModel(history: History) -> MainTableCellViewModel
    
    func mainCellViewModel(wallet: Wallet) -> MainTableCellViewModel
}
