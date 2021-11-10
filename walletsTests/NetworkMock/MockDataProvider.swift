//
//  MockDataProvider.swift
//  walletsTests
//
//  Created by Bogdan Redkin on 10.11.2021.
//

import Foundation
import Combine
import Alamofire
@testable import wallets

final class MockDataProvider: WalletsDataProviderProtocol, HistoryDataProviderProtocol {
    
    let walletsResponse: WalletsResponse
    let historyResponse: HistoryResponse
    let error: AFError?
    
    init(wallets: WalletsResponse, histories: HistoryResponse, error: AFError? = nil) {
        self.walletsResponse = wallets
        self.historyResponse = histories
        self.error = error
    }
    
    func historyPublisher(page: Int) -> AnyPublisher<HistoryResponse, AFError> {
        return generatePublisher(data: historyResponse)
    }
    
    func walletsPublisher() -> AnyPublisher<WalletsResponse, AFError> {
        return generatePublisher(data: walletsResponse)
    }
    
    private func generatePublisher<T>(data: T) -> AnyPublisher<T, AFError> {
        let publisher = PassthroughSubject<T, AFError>()
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            if let error = self.error {
                publisher.send(completion: .failure(error))
            } else {
                publisher.send(data)
            }
        }
        
        return publisher.eraseToAnyPublisher()
    }
    
    func enableErrors(_ isEnabled: Bool) {
        
    }
}
