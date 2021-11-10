//
//  DataProvidingProtocols.swift
//  wallets
//
//  Created by Bogdan Redkin on 10.11.2021.
//

import Foundation
import Alamofire
import Combine

protocol DataProviderProtocol {
    func enableErrors(types: [MainViewModel.Section])
}

protocol WalletsDataProviderProtocol: DataProviderProtocol {
    func walletsPublisher() -> AnyPublisher<WalletsResponse, AFError>
}

protocol HistoryDataProviderProtocol: DataProviderProtocol {
    func historyPublisher(page: Int) -> AnyPublisher<HistoryResponse, AFError>
}
