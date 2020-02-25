//
//  StubModel.swift
//  NXNetworkingTests
//
//  Created by Nick Xirotyris on 25/2/20.
//

import Foundation


struct StubModel: Decodable {
    let name: String
    let lastName: String
    let phone: Double
    let email: String
    let address: StubAddress
}

struct StubAddress: Decodable {
    let street: String
    let region: String
    let state: String
}


struct QueryParamsRequest: Encodable {
    public var page = 0
    public var pageSize = 100
    public var name: String?
}
