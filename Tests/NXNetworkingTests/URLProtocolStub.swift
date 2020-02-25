//
//  File.swift
//  NXNetworkingTests
//
//  Created by Nick Xirotyris on 25/2/20.
//

import Foundation

enum StubURL {
    case data, json, string, decodable
}

class URLProtocolStub: URLProtocol {
    
    static var stubURLS: [StubURL: Data] {
        return [.data: "This is a data response".data(using: .utf8)!,
                .json: json,
                .string: "This is a string response".data(using: .utf8)!,
                .decodable: json]
    }
    
    static var json: Data {
        let json = ["name": "John",
                    "lastName": "Appleseed",
                    "phone": 8008008000,
                    "email": "john@apple.com",
                    "address": ["street": "1 Infinity Loop", "region": "Palo Alto", "state": "California"]
        ] as [String: Any]
        return try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        if let url = request.url {
            print("mock request:\n\(request)")
            // …and if we have test data for that URL…
            if url.pathComponents.contains("data") {
                let response = HTTPURLResponse.init(url: request.url!, statusCode: 200, httpVersion: "2.0", headerFields: nil)!
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: URLProtocolStub.stubURLS[.data]!)
            } else if url.pathComponents.contains("json") {
                let response = HTTPURLResponse.init(url: request.url!, statusCode: 200, httpVersion: "2.0", headerFields: nil)!
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: URLProtocolStub.stubURLS[.json]!)
            } else if url.pathComponents.contains("decodable") {
                let response = HTTPURLResponse.init(url: request.url!, statusCode: 200, httpVersion: "2.0", headerFields: nil)!
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: URLProtocolStub.stubURLS[.decodable]!)
            } else if url.pathComponents.contains("string") {
                let response = HTTPURLResponse.init(url: request.url!, statusCode: 200, httpVersion: "2.0", headerFields: nil)!
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: URLProtocolStub.stubURLS[.string]!)
            }
        }
        
        // mark that we've finished
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {
    }
}
