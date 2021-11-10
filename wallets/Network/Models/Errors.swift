//
//  Errors.swift
//  wallets
//
//  Created by Bogdan Redkin on 10.11.2021.
//

import Foundation
import Alamofire

enum DefinedError: Equatable, Error {
    static func == (lhs: DefinedError, rhs: DefinedError) -> Bool {
        return lhs.message == rhs.message
    }
    
    case pageNotFound
    case requestThrottled(BackendError)
    case internalServerError
    case responseIsEmpty
    case afError(AFError)
    case unknown
    
    init(backendError: BackendError) {
        switch backendError.code {
        case "throttled":
            self = .requestThrottled(backendError)
        default:
            self = .unknown
        }
    }
    
    init(code: Int) {
        switch code {
        case 404:
            self = .pageNotFound
        case 500:
            self = .internalServerError
        default:
            self = .unknown
        }
    }
    
    init(error: AFError) {
        self = .afError(error)
    }
    
    init(from error: AFError) {
        self = (error.underlyingError as? DefinedError) ?? .unknown
    }

    var message: String {
        switch self {
        case .pageNotFound:
            return "Requested page not found"
        case .internalServerError:
            return "Internal Server Error"
        case .responseIsEmpty:
            return "Response is empty"
        case .afError(let error):
            return error.localizedDescription
        case .unknown:
            return "Unknown Server Error"
        case .requestThrottled(let backendError):
            return backendError.message
        }
    }
}

struct BackendErrorResponse: Codable {
    let errors: BackendError
    
    enum CodingKeys: String, CodingKey {
        case errors = "errors"
        case nonFieldErrors = "non_field_errors"
    }
    
    init(errors: BackendError) {
        self.errors = errors
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let errorsContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .errors)
                
        errors = try errorsContainer.decode(BackendError.self, forKey: .nonFieldErrors)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        var errorsContainer = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .errors)
        
        try errorsContainer.encode(errors, forKey: .nonFieldErrors)
    }
}

struct BackendError: Codable {
    let code: String
    let message: String
}
