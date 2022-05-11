//
//  RemoteDataProvider.swift
//  wallets
//
//  Created by Bogdan Redkin on 10.11.2021.
//

import Foundation
import Alamofire
import Combine

final class RemoteDataProvider: WalletsDataProviderProtocol, HistoryDataProviderProtocol {
    
    private
    let host = "https://demo9797017.mockable.io/"
    
    private
    var enabledErrorsForTypes: [MainViewModel.Section] = []
            
    func historyPublisher(page: Int) -> AnyPublisher<HistoryResponse, AFError> {
        return APIRequest.history(page: page)
            .request(with: host, enabledErrors: enabledErrorsForTypes.contains(.history))
            .publishTwoDecodable(type: HistoryResponse.self)
            .value()
    }
    
    func walletsPublisher() -> AnyPublisher<WalletsResponse, AFError> {
        return APIRequest.wallets
            .request(with: host, enabledErrors: enabledErrorsForTypes.contains(.wallets))
            .publishTwoDecodable(type: WalletsResponse.self)
            .value()
    }
    
    func enableErrors(types: [MainViewModel.Section]) {
        self.enabledErrorsForTypes = types
    }
    
}
