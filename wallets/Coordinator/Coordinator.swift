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
}
