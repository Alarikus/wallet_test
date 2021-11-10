//
//  WalletsAPI.swift
//  wallets
//
//  Created by Bogdan Redkin on 09.11.2021.
//

//TODO: - Customize Alamofire request handling
import Foundation
import Alamofire
import Combine

protocol WalletsDataProviderProtocol {
    func walletsPublisher() -> AnyPublisher<WalletsResponse, AFError>
}

protocol HistoryDataProviderProtocol {
    func historyPublisher(page: Int) -> AnyPublisher<HistoryResponse, AFError>
}

final class RemoteDataProvider: WalletsDataProviderProtocol, HistoryDataProviderProtocol {
    
    private
    let host = "http://www.amock.io/api/aldammit/"
    
    func historyPublisher(page: Int) -> AnyPublisher<HistoryResponse, AFError> {
        return APIRequest.history(page: page).request(with: host).publishDecodable(type: HistoryResponse.self).value()
    }
    
    func walletsPublisher() -> AnyPublisher<WalletsResponse, AFError> {
        return APIRequest.wallets.request(with: host).publishDecodable(type: WalletsResponse.self).value()
    }
}

enum APIRequest {
    case wallets
    case history(page: Int)
}

extension APIRequest {
    
    private struct Components {
        var path: String!
        var headers: HTTPHeaders = [HTTPHeader.contentType("application/json")]
        var parameters: Parameters = [:]
    }
    
    private var components: Components {
        var components = Components()
        
        switch self {
        case .wallets:
            components.path = "wallets"
        case .history(let page):
            components.parameters["page"] = page.string
            components.parameters["offset"] = 20.string
            components.path = "histories"
        }
            
        return components
    }
    
    func request(with host: String) -> Alamofire.DataRequest {
        return AF.request(host + components.path,
                          method: .get,
                          parameters: components.parameters,
                          headers: components.headers)
    }
    
}
