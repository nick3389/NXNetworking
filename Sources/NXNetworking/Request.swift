//
//  File.swift
//  
//
//  Created by Nick Xirotyris on 25/1/20.
//

import Foundation


public protocol Request {
    var name: String {get set}
    var urlPath: String {get set}
    var parameters: [String: Any?] {get set}
    var headers: [String: String] {get}
    
    mutating func addHeader(_ key: String, value: String)
}
