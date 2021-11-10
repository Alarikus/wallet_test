//
//  DataProvidingProtocols.swift
//  wallets
//
//  Created by Bogdan Redkin on 10.11.2021.
//

import Foundation
import Alamofire
import Combine

protocol WalletsDataProviderProtocol {
    func walletsPublisher() -> AnyPublisher<WalletsResponse, AFError>
}

protocol HistoryDataProviderProtocol {
    func historyPublisher(page: Int) -> AnyPublisher<HistoryResponse, AFError>
}
