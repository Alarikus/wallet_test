//
//  SerializableError.swift
//  wallets
//
//  Created by Bogdan Redkin on 10.11.2021.
//

import Foundation
import Alamofire

final class TwoDecodableResponseSerializer<T: Decodable>: ResponseSerializer {
    
    lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    private lazy var successSerializer = DecodableResponseSerializer<T>(decoder: decoder)
    private lazy var errorSerializer = DecodableResponseSerializer<BackendErrorResponse>(decoder: decoder)
    
    func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> T {
        
        guard error == nil else {
            throw DefinedError.unknown
        }
        
        guard let response = response else {
            throw DefinedError.responseIsEmpty
        }
        
        do {
            if response.statusCode < 200 || response.statusCode >= 300 {
                let result = try errorSerializer.serialize(request: request,
                                                           response: response,
                                                           data: data,
                                                           error: nil)
                throw DefinedError(backendError: result.errors)
            } else {
                let result = try successSerializer.serialize(request: request,
                                                             response: response,
                                                             data: data,
                                                             error: nil)
                return result
            }
        } catch let error {
            if type(of: error) == DefinedError.self {
                throw error
            } else {
                throw DefinedError(error: AFError.responseSerializationFailed(reason: .customSerializationFailed(error: error)))
            }
        }
    }
    
}

extension DataRequest {
    
    func publishTwoDecodable<T: Decodable>(type: T.Type = T.self,
                                           queue: DispatchQueue = .main) -> DataResponsePublisher<T> {
        return publishResponse(using: TwoDecodableResponseSerializer<T>(), on: queue)
    }
    
}
