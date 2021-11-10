//
//  HistoryDetailCoordinator.swift
//  wallets
//
//  Created by Bogdan Redkin on 10.11.2021.
//

import UIKit
import Combine

final class HistoryDetailCoordinator: Coordinator {
    
    let navigationController: UINavigationController

    private let viewModelProvider: ViewModelProvider
    private let selectedHistory: History
    
    private var bindings = Set<AnyCancellable>()
    
    init(navigation: UINavigationController, viewModelProvider: ViewModelProvider, selectedHistory: History) {
        self.navigationController = navigation
        self.viewModelProvider = viewModelProvider
        self.selectedHistory = selectedHistory
    }
    
    func start() {
        let historyDetailController = HistoryDetailViewController()
        historyDetailController.viewModel = viewModelProvider.historyViewModel(selectedHistory: selectedHistory)
        historyDetailController.extendedLayoutIncludesOpaqueBars = true
        historyDetailController.loadViewIfNeeded()
        
        navigationController.pushViewController(historyDetailController, animated: true)
        
        historyDetailController.$backButtonPublisher.sink { [weak self] publisher in
            guard let self = self else { return }
            publisher?.receive(on: DispatchQueue.main).sink(receiveValue: { _ in
                self.navigationController.popViewController(animated: true)
                self.bindings.forEach({ $0.cancel() })
                self.bindings.removeAll()
            }).store(in: &self.bindings)
        }.store(in: &bindings)
    }
}
