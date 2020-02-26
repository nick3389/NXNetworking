//
//  NXNetworking.swift
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

public enum ResponseType<T: Decodable> {
    case data
    case string
    case json
    case decodable(T.Type, JSONDecoder)
}

public typealias NonDecodableResponseType = ResponseType<Bool>

protocol RESTable {
    associatedtype U
    func get<P: Encodable, T: Decodable>(request: Request<P>, response: ResponseType<T>) -> AnyPublisher<NXResponse<U>, NXError>
    func put<P: Encodable, T: Decodable>(request: Request<P>, response: ResponseType<T>) -> AnyPublisher<NXResponse<U>, NXError>
    func patch<P: Encodable, T: Decodable>(request: Request<P>, response: ResponseType<T>) -> AnyPublisher<NXResponse<U>, NXError>
    func post<P: Encodable, T: Decodable>(request: Request<P>, response: ResponseType<T>) -> AnyPublisher<NXResponse<U>, NXError>
    func delete<P: Encodable, T: Decodable>(request: Request<P>, response: ResponseType<T>) -> AnyPublisher<NXResponse<U>, NXError>
}

public struct NXNetworking<N>: URLSessionPublisher {
    public typealias U = N
    
    internal var configuration: URLSessionConfiguration?
    
    public init() {}
    
    public init(configuration: URLSessionConfiguration) {
        self.configuration = configuration
    }
    
    public func get<P: Encodable, T: Decodable>(request: Request<P>, response: ResponseType<T>) -> AnyPublisher<NXResponse<U>, NXError> {
        return handleRequest(request, withResponseType: response, method: .get)
    }

    public func put<P: Encodable, T: Decodable>(request: Request<P>, response: ResponseType<T>) -> AnyPublisher<NXResponse<U>, NXError> {
        return handleRequest(request, withResponseType: response, method: .put)
    }

    public func patch<P: Encodable, T: Decodable>(request: Request<P>, response: ResponseType<T>) -> AnyPublisher<NXResponse<U>, NXError> {
        return handleRequest(request, withResponseType: response, method: .patch)
    }

    public func post<P: Encodable, T: Decodable>(request: Request<P>, response: ResponseType<T>) -> AnyPublisher<NXResponse<U>, NXError> {
        return handleRequest(request, withResponseType: response, method: .post)
    }

    public func delete<P: Encodable, T: Decodable>(request: Request<P>, response: ResponseType<T>) -> AnyPublisher<NXResponse<U>, NXError>  {
        return handleRequest(request, withResponseType: response, method: .delete)
    }
    
    //MARK: Internal API
    func handleRequest<P: Encodable, T: Decodable>(_ request: Request<P>, withResponseType type: ResponseType<T>, method: HTTPMethod) -> AnyPublisher<NXResponse<U>, NXError> {
        return createURLRequest(request: request, method: method)
            .flatMap({self.dataTask(method, request: $0, configuration: self.configuration)})
            .flatMap(maxPublishers: .max(1), {self.decode($0, type: type)})
            .eraseToAnyPublisher()
    }
    
    func createURLRequest<P: Encodable>(request: Request<P>, method: HTTPMethod) -> AnyPublisher<URLRequest, NXError> {
        guard let url = URL(string: request.urlPath) else {
            return Fail(error: NXError.invalidURL).eraseToAnyPublisher()
        }
        
        var r = URLRequest(url: url)
        r.httpMethod = method.name
        r.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        r.timeoutInterval = 100.0
        r.allHTTPHeaderFields = request.headers
        if let builder = request.builder {
            return builder.build(params: request.parameters, forRequest: r)
        }
        
        return Future<URLRequest, NXError> { (promise) in
            promise(.success(r))
        }.eraseToAnyPublisher()
    }
    
    
    func decode<T: Decodable>(_ response: NXResponse<Data>, type: ResponseType<T>) -> AnyPublisher<NXResponse<U>, NXError> {
        switch type {
        case .data:
            return Future<NXResponse<U>, NXError> { (promise) in
                promise(.success(response as! NXResponse<U>))
            }.eraseToAnyPublisher()
        case .string:
            return Future<NXResponse<U>, NXError> { (promise) in
                guard let stringData = String(data: response.data, encoding: .utf8) else {
                    promise(.failure(NXError.parsing("no string data in response")))
                    return
                }
                promise(.success(NXResponse<String>(response: response.response, data: stringData) as! NXResponse<U>))
            }.eraseToAnyPublisher()
        case .json:
            return Just(response)
                .tryMap { (r) -> NXResponse<U> in
                    let json = try JSONSerialization.jsonObject(with: r.data, options: .allowFragments) as! U
                    return NXResponse<U>(response: r.response, data: json)
                }.mapError({NXError.serialization($0)})
                .eraseToAnyPublisher()
        case .decodable(let P, let decoder):
            return Just(response.data).decode(type: P.self, decoder: decoder)
                .map({NXResponse<T>(response: response.response, data: $0) as! NXResponse<U>})
                .mapError({NXError.serialization($0)})
                .eraseToAnyPublisher()
        }
    }
}
