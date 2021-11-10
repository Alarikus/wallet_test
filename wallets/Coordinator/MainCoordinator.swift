//
//  MainCoordinator.swift
//  wallets
//
//  Created by Bogdan Redkin on 09.11.2021.
//

import UIKit
import Combine

final class MainCoordinator: Coordinator {
    
    let navigationController: UINavigationController

    private let viewModelProvider: ViewModelProvider
    
    private var bindings = Set<AnyCancellable>()
    
    init(navigation: UINavigationController, viewModelProvider: ViewModelProvider) {
        self.navigationController = navigation
        self.viewModelProvider = viewModelProvider
    }
    
    func start() {
        let mainViewController = MainViewController(style: .insetGrouped)
        mainViewController.viewModel = viewModelProvider.mainViewModel()
        mainViewController.extendedLayoutIncludesOpaqueBars = true

        mainViewController.viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { selectedState in
                switch selectedState {
                case .transition(let history):
                    let historyDetailCoordinator = HistoryDetailCoordinator(navigation: self.navigationController,
                                                                            viewModelProvider: self.viewModelProvider,
                                                                            selectedHistory: history)
                    historyDetailCoordinator.start()
                default:
                    break
                }
            }.store(in: &bindings)
        
        navigationController.setViewControllers([mainViewController], animated: true)
    }
}
