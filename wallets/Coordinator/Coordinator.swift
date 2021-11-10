//
//  Coordinator.swift
//  wallets
//
//  Created by Bogdan Redkin on 09.11.2021.
//

import UIKit

protocol Coordinator {
    
    var navigationController: UINavigationController { get }
    
    func start()
    
    func showAlert(title: String, message: String)
}

extension Coordinator {
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { _ in
            alertController.dismiss(animated: true, completion: nil)
        }))
        navigationController.present(alertController, animated: true, completion: nil)
    }
    
}
