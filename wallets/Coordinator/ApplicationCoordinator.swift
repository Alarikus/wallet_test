//
//  ApplicationCoordinator.swift
//  wallets
//
//  Created by Bogdan Redkin on 09.11.2021.
//

import UIKit

final class ApplicationCoordinator: Coordinator {
    
    let navigationController: UINavigationController

    private let window: UIWindow
    private let childCoordinator: Coordinator
    
    init(window: UIWindow) {
        self.window = window
        
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().prefersLargeTitles = true
        
        self.navigationController = UINavigationController()
        self.childCoordinator = MainCoordinator(navigation: navigationController,
                                                viewModelProvider: MainViewModelProvider())
    }

    func start() {
        window.rootViewController = navigationController
        childCoordinator.start()
        window.makeKeyAndVisible()
    }
}
