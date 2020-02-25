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
    public init() {}
    public var urlPath: String?
    public var parameters: Parameters?
    public var headers: [String: String]?
    public var builder: ParametersBuilder?
    
    public mutating func addHeader(_ key: String, value: String) {
        headers?[key] = value
    }
}


public protocol Builbadle {
    func build<Parameters: Encodable>(params: Parameters, forRequest request: URLRequest) -> AnyPublisher<URLRequest, NXError>
}

public enum ParametersBuilder: Builbadle {
    case json(JSONEncoder), query(JSONEncoder)
    
    public func build<Parameters>(params: Parameters, forRequest request: URLRequest) -> AnyPublisher<URLRequest, NXError> where Parameters : Encodable {
        var r = request
        
        switch self {
        case .json(let encoder):
            return Just(params)
            .encode(encoder: encoder)
            .map({ (data) -> URLRequest in
                r.httpBody = data
                if r.value(forHTTPHeaderField: "Content-Type") == nil {
                    r.addValue("application/json", forHTTPHeaderField: "Content-Type")
                }
                return r
            })
            .mapError({NXError.serialization($0)})
            .eraseToAnyPublisher()
        case .query(let encoder):
            return Just(params)
            .encode(encoder: encoder)
            .tryMap({try JSONSerialization.jsonObject(with: $0, options: .allowFragments) as! [String: Any]})
            .tryMap { (params) -> URLRequest in
                let queryString = params.compactMapValues({$0}).map({"\($0)=\($1)"}).joined(separator: "&")
                
                guard var urlPath = request.url?.absoluteString else {
                    throw NXError.invalidURL
                }
                urlPath.append("?\(queryString)")
                guard let finalURL = urlPath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                    throw NXError.unknown("error in parameterizing url")
                }
                r.url = URL(string: finalURL)
                return r
            }
            .mapError({NXError.serialization($0)})
            .eraseToAnyPublisher()
        }
    }
}
