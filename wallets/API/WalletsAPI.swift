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
