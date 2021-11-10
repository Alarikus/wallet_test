//
//  MainViewModelProvider.swift
//  wallets
//
//  Created by Bogdan Redkin on 09.11.2021.
//

import Foundation

final class MainViewModelProvider: ViewModelProvider {
    
    func historyViewModel(selectedHistory: History) -> HistoryDetailViewModel {
        return HistoryDetailViewModel(selectedHistory)
    }
    
    func mainViewModel() -> MainViewModel {
        return MainViewModel(RemoteDataProvider(), viewModelProvider: self)
    }
    
    func mainCellViewModel(wallet: Wallet) -> MainTableCellViewModel {
        return MainTableCellViewModel(wallet: wallet)
    }
    
    func mainCellViewModel(history: History) -> MainTableCellViewModel {
        return MainTableCellViewModel(history: history)
    }
}
