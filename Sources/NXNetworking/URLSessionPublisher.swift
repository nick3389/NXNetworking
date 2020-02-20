//
//  URLSessionPublisher.swift
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




internal protocol URLSessionPublisher {
    func dataTask(_ method: HTTPMethod, request: URLRequest) -> AnyPublisher<NXResponse<Data>, NXError>
}

extension URLSessionPublisher {
    func dataTask(_ method: HTTPMethod, request: URLRequest) -> AnyPublisher<NXResponse<Data>, NXError> {
        
        let session = URLSession.shared

        return session.dataTaskPublisher(for: request)
        .tryMap({ res -> NXResponse<Data> in
            guard let r = res.response as? HTTPURLResponse else {
                throw NXError.unknown("")
            }
            return NXResponse<Data>(response: r, data: res.data)
        })
        .mapError({ (e) -> NXError in
            if let error = e as? URLError {
                return NXError.network(error)
            }
            return NXError.unknown(nil)
        })
        .eraseToAnyPublisher()
    }
}