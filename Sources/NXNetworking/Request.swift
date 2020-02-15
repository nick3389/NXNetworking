//
//  Request.swift
//
//  Copyright (c) 2020 nick3389
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation
import Combine

public typealias Parameters = [String: Any]

public struct Request<Parameters: Encodable> {
    var name: String?
    var urlPath: String
    var parameters: Parameters?
    var headers: [String: String]
    var builder: ParametersBuilder
    
    mutating func addHeader(_ key: String, value: String) {
        headers[key] = value
    }
}


public protocol ParametersBuilder {
    func build<Parameters: Encodable>(params: Parameters, forRequest: URLRequest) -> AnyPublisher<URLRequest, NXError>
}


public struct JSONParamsBuilder: ParametersBuilder {
    public let encoder: JSONEncoder
    
    public func build<Parameters: Encodable>(params: Parameters, forRequest request: URLRequest) -> AnyPublisher<URLRequest, NXError> {
        var request = request

        return Just(params)
            .encode(encoder: encoder)
            .map({ (data) -> URLRequest in
                request.httpBody = data
                if request.value(forHTTPHeaderField: "Content-Type") == nil {
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                }
                return request
            })
            .mapError({NXError.serialization($0)})
            .eraseToAnyPublisher()
    }
}

public struct QueryParamsBuilder: ParametersBuilder {
    public let encoder: JSONEncoder
    
    public func build<Parameters: Encodable>(params: Parameters, forRequest request: URLRequest) -> AnyPublisher<URLRequest, NXError> {
        var r = request
        
        return Just(params)
            .encode(encoder: encoder)
            .tryMap({try JSONSerialization.jsonObject(with: $0, options: .allowFragments) as! [String: Any]})
            .map { (params) -> URLRequest in
                let queryString = params.compactMapValues({$0}).map({"\($0)=\($1)"}).joined(separator: "&")
                r.url?.appendPathComponent("?\(queryString)")
                return request
            }
            .mapError({NXError.serialization($0)})
            .eraseToAnyPublisher()
    }
}


