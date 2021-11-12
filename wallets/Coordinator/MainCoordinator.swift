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
        mainViewController.viewModel = viewModelProvider.mainViewModel(coordinator: self)
        mainViewController.extendedLayoutIncludesOpaqueBars = true
    
        navigationController.setViewControllers([mainViewController], animated: true)
        
        let delayBarButton = UIBarButtonItem(image: UIImage(systemName: "clock.arrow.circlepath"),
                                             style: .done,
                                             target: self,
                                             action: #selector(delayButtonPressed))
        delayBarButton.tintColor = .label
        delayBarButton.customView?.isUserInteractionEnabled = true
        
        let errorsBarButton = UIBarButtonItem(image: UIImage(systemName: "exclamationmark.triangle.fill"),
                                              style: .done,
                                              target: self,
                                              action: #selector(errorsButtonPressed))
        errorsBarButton.customView?.isUserInteractionEnabled = true
        errorsBarButton.tintColor = .label

        mainViewController.navigationItem.rightBarButtonItems = [errorsBarButton, delayBarButton]
    }
    
    func openHistoryDetail(history: History) {
        let historyDetailCoordinator = HistoryDetailCoordinator(navigation: self.navigationController,
                                                                viewModelProvider: self.viewModelProvider,
                                                                selectedHistory: history)
        historyDetailCoordinator.start()
    }
    
    @objc private
    func delayButtonPressed(item: UIBarButtonItem) {
        mainViewController.viewModel.isRequestsWithDelayEnabled.toggle()
        
        if mainViewController.viewModel.isRequestsWithDelayEnabled {
            item.tintColor = .systemRed
            self.showAlert(title: "Delay", message: "Enabled delay for each request for 5 sec.")
        } else {
            item.tintColor = .label
            self.showAlert(title: "Delay", message: "Disabled delay for each request for 5 sec.")
        }
    }
    
    @objc private
    func errorsButtonPressed(item: UIBarButtonItem) {
        let alert = UIAlertController(title: "Enabling errors in response", message: "Choose response type", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "All", style: .default, handler: { _ in
            self.mainViewController.viewModel.requestsWithErrors = [.history, .wallets]
            alert.dismiss(animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Wallets", style: .default, handler: { _ in
            self.mainViewController.viewModel.requestsWithErrors = [.wallets]
            alert.dismiss(animated: true, completion: nil)
        }))

        alert.addAction(UIAlertAction(title: "Histories", style: .default, handler: { _ in
            self.mainViewController.viewModel.requestsWithErrors = [.history]
            alert.dismiss(animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Nothing", style: .default, handler: { _ in
            self.mainViewController.viewModel.requestsWithErrors = []
            alert.dismiss(animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { _ in
            alert.dismiss(animated: true, completion: nil)
        }))
                
        navigationController.present(alert, animated: true)
        
        if (mainViewController.viewModel.requestsWithErrors ?? []).isEmpty == false {
            item.tintColor = .systemRed
        } else {
            item.tintColor = .label
        }
    }
    
}
