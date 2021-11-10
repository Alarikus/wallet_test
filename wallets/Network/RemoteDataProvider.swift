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
    let host = "http://www.amock.io/api/aldammit/"
    
    private
    var isErrorsEnabled = false
            
    func historyPublisher(page: Int) -> AnyPublisher<HistoryResponse, AFError> {
        return APIRequest.history(page: page)
            .request(with: host)
            .publishTwoDecodable(type: HistoryResponse.self)
            .value()
    }
    
    func walletsPublisher() -> AnyPublisher<WalletsResponse, AFError> {
        return APIRequest.wallets
            .request(with: host, enabledErrors: isErrorsEnabled)
            .publishTwoDecodable(type: WalletsResponse.self)
            .value()
    }
    
    func enableErrors(_ isEnabled: Bool) {
        self.isErrorsEnabled = isEnabled
    }
}