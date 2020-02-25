import XCTest
@testable import NXNetworking

final class NXNetworkingTests: XCTestCase {
    
    func testDataResponse() {
        let expectation = self.expectation(description: self.debugDescription)
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        
        let networking = NXNetworking<Data>(configuration: config)
        let request = RequestWithoutParameters(path: "https://www.apple.com/data")
        
        let cancellable = networking.get(request: request, response: NonDecodableResponseType.data).sink(receiveCompletion: { (result) in
            switch result {
            case .finished:
                XCTAssert(true)
            case .failure(let error):
                XCTFail("Failed with error: \(error)")
                expectation.fulfill()
            }
        }, receiveValue: { (r) in
            print(r.data)
            let message = String(data: r.data, encoding: .utf8)
            let expectedMessage = String(data: URLProtocolStub.stubURLS[.data]!, encoding: .utf8)
            XCTAssertEqual(message, expectedMessage)
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 30)
        cancellable.cancel()
    }
    
    func testQueryParamsRequestWithJSONResponse() {
        let expectation = self.expectation(description: self.debugDescription)
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        
        let networking = NXNetworking<[String: Any]>(configuration: config)
        var request = Request<QueryParamsRequest>(path: "https://www.apple.com/json")
        request.parameters = QueryParamsRequest(name: "John Appleseed")
        request.builder = .query(JSONEncoder())
        
        let cancellable = networking.get(request: request, response: NonDecodableResponseType.json).sink(receiveCompletion: { (result) in
            switch result {
            case .finished:
                XCTAssert(true)
            case .failure(let error):
                XCTFail("Failed with error: \(error)")
                expectation.fulfill()
            }
        }, receiveValue: { (r) in
            print(r.data as AnyObject)
            XCTAssertNotNil(r.data["name"], "name is nil")
            XCTAssertNotNil(r.data["lastName"], "last name is nil")
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 30)
        cancellable.cancel()
    }
    
    func testDecodableResponse() {
        let expectation = self.expectation(description: self.debugDescription)
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        
        let networking = NXNetworking<StubModel>(configuration: config)
        let request = RequestWithoutParameters(path: "https://www.apple.com/decodable")
        
        let cancellable = networking.get(request: request, response: ResponseType.decodable(StubModel.self)).sink(receiveCompletion: { (result) in
            switch result {
            case .finished:
                XCTAssert(true)
            case .failure(let error):
                XCTFail("Failed with error: \(error)")
                expectation.fulfill()
            }
        }, receiveValue: { (r) in
            print(r.data)
            let model = r.data
            XCTAssertEqual(model.name, "John")
            XCTAssertEqual(model.lastName, "Appleseed")
            XCTAssertEqual(model.email, "john@apple.com")
            XCTAssertEqual(model.phone, Double(8008008000))
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 30)
        cancellable.cancel()
    }
    
    func testStringResponse() {
        let expectation = self.expectation(description: self.debugDescription)
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        
        let networking = NXNetworking<String>(configuration: config)
        let request = RequestWithoutParameters(path: "https://www.apple.com/string")
        
        let cancellable = networking.get(request: request, response: NonDecodableResponseType.string).sink(receiveCompletion: { (result) in
            switch result {
            case .finished:
                XCTAssert(true)
            case .failure(let error):
                XCTFail("Failed with error: \(error)")
                expectation.fulfill()
            }
        }, receiveValue: { (r) in
            print(r.data)
            let expectedMessage = String(data: URLProtocolStub.stubURLS[.string]!, encoding: .utf8)
            XCTAssertEqual(r.data, expectedMessage)
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 30)
        cancellable.cancel()
    }
}



