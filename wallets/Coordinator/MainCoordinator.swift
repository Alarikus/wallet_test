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
    
    private var mainViewController: MainViewController!
    
    init(navigation: UINavigationController, viewModelProvider: ViewModelProvider) {
        self.navigationController = navigation
        self.viewModelProvider = viewModelProvider
    }
    
    func start() {
        mainViewController = MainViewController(style: .insetGrouped)
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
                case .error(let error):
                    if error != .pageNotFound {
                        self.showAlert(title: "Error", message: error.message)
                    }
                default:
                    break
                }
            }.store(in: &bindings)
        
        let delayBarButton = UIBarButtonItem(image: UIImage(systemName: "clock.arrow.circlepath"),
                                    style: .plain,
                                             target: self, action: #selector(delayButtonPressed(item:)))
        delayBarButton.tintColor = .label
        
        let errorsBarButton = UIBarButtonItem(image: UIImage(systemName: "exclamationmark.triangle.fill"),
                                              style: .plain,
                                              target: self,
                                              action: #selector(errorsButtonPressed(item:)))
        errorsBarButton.tintColor = .label

        mainViewController.navigationItem.rightBarButtonItems = [errorsBarButton, delayBarButton]
        
        navigationController.setViewControllers([mainViewController], animated: true)
    }
    
    @objc private
    func delayButtonPressed(item: UIBarButtonItem) {
        mainViewController.viewModel.isRequestWithDelayEnabled.toggle()
        
        if mainViewController.viewModel.isRequestWithDelayEnabled {
            item.tintColor = .systemRed
            self.showAlert(title: "Delay", message: "Enabled delay for each request for 5 sec.")
        } else {
            item.tintColor = .label
            self.showAlert(title: "Delay", message: "Disabled delay for each request for 5 sec.")
        }
    }
    
    @objc private
    func errorsButtonPressed(item: UIBarButtonItem) {
        mainViewController.viewModel.isRequestsWithErrorsEnabled.toggle()
        mainViewController.viewModel.dataProvider.enableErrors(mainViewController.viewModel.isRequestsWithErrorsEnabled)
        
        if mainViewController.viewModel.isRequestsWithErrorsEnabled {
            item.tintColor = .systemRed
            self.showAlert(title: "Errors", message: "Enabled responses with error codes 429 and 500.")
        } else {
            item.tintColor = .label
            self.showAlert(title: "Errors", message: "Disabled reponses with error codes")
        }
    }
    
}
