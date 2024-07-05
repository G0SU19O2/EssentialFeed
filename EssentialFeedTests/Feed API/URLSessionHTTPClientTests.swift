//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Quốc Huy Nguyễn on 2/7/24.
//

import EssentialFeed
import Foundation
import XCTest

class URLSessionHTTPClient {
    var session: URLSession
    init(session: URLSession = .shared) {
        self.session = session
    }

    struct UnexpectedValuesRepresentation: Error {}

    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let error {
                completion(.failure(error))
            } else if let data, let response = response as? HTTPURLResponse {
                completion(.success((data, response)))
            } else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }

    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequests()
    }

    func test_getFromURL_performsGETRequestWithURL() {
        let url = anyURL()
        let sut = makeSUT()
        let expectation = expectation(description: "Wait for complete")
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            expectation.fulfill()
        }
        sut.get(from: url) { _ in }
        wait(for: [expectation], timeout: 1)
    }

    func test_getFromURL_failsOnRequestError() {
        let requestError = anyNSError()
        let receivedError = resultErrorFor(data: anyData(), response: anyURLResponse(), error: requestError)
        XCTAssertEqual(requestError.domain, (receivedError as? NSError)?.domain)
        XCTAssertEqual(requestError.code, (receivedError as? NSError)?.code)
    }

    func test_getFromURL_failsOnAllInvalidRepresentableCases() {
        let httpResponse = anyHTTPURLResponse()
        let nonHTTPResponse = anyURLResponse()
        let data = anyData()
        let error = anyNSError()
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPResponse, error: nil))
        XCTAssertNotNil(resultErrorFor(data: data, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: data, response: nil, error: error))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPResponse, error: error))
        XCTAssertNotNil(resultErrorFor(data: nil, response: httpResponse, error: error))
        XCTAssertNotNil(resultErrorFor(data: data, response: nonHTTPResponse, error: error))
        XCTAssertNotNil(resultErrorFor(data: data, response: httpResponse, error: error))
        XCTAssertNotNil(resultErrorFor(data: data, response: nonHTTPResponse, error: nil))
    }

    func test_getFromURL_succeedsWithEmptyDataOnHTTPURLResponseWithNilData() {
        let anyHttpResponse = anyHTTPURLResponse()
        URLProtocolStub.stub(data: nil, response: anyHttpResponse, error: nil)
        let sut = makeSUT()
        let url = anyURL()
        let expectation = expectation(description: "Wait for complete")
        sut.get(from: url) { result in
            switch result {
            case let .success((data, response)):
                let emptyData = Data()
                XCTAssertEqual(emptyData, data)
                XCTAssertEqual(anyHttpResponse.url, response.url)
                XCTAssertEqual(anyHttpResponse.statusCode, response.statusCode)
            case .failure:
                XCTFail("Expected success, got \(result) instead")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func test_getFromURL_succeedsOnHTTPURLResponseWithData() {
        let anyHttpResponse = anyHTTPURLResponse()
        let anyData = anyData()
        URLProtocolStub.stub(data: anyData, response: anyHttpResponse, error: nil)
        let sut = makeSUT()
        let url = anyURL()
        let expectation = expectation(description: "Wait for complete")
        sut.get(from: url) { result in
            switch result {
            case let .success((data, response)):
                XCTAssertEqual(anyData, data)
                XCTAssertEqual(anyHttpResponse.url, response.url)
                XCTAssertEqual(anyHttpResponse.statusCode, response.statusCode)
            case .failure:
                XCTFail("Expected success, got \(result) instead")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    // MARK: - Helpers

    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?) -> Error? {
        let url = anyURL()
        URLProtocolStub.stub(data: data, response: response, error: error)
        let sut = makeSUT()
        let expectation = expectation(description: "Wait for complete")
        var capturedError: Error?
        sut.get(from: url) { result in
            switch result {
            case let .failure(error):
                capturedError = error
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
        return capturedError
    }

    private func makeSUT(filePath: StaticString = #filePath, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeads(sut, filePath: #filePath, line: #line)
        return sut
    }

    private func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }

    private func anyData() -> Data {
        return Data("any data".utf8)
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 1)
    }

    private func anyURLResponse() -> URLResponse {
        return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }

    private func anyHTTPURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }

    private class URLProtocolStub: URLProtocol {
        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }

        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }

        override init(request: URLRequest, cachedResponse: CachedURLResponse?, client: (any URLProtocolClient)?) {
            super.init(request: request, cachedResponse: cachedResponse, client: client)
        }

        static func startInterceptingRequests() {
            URLProtocol.registerClass(Self.self)
        }

        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(Self.self)
            stub = nil
            requestObserver = nil
        }

        static func observeRequests(observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }

        override class func canInit(with request: URLRequest) -> Bool {
            requestObserver?(request)
            return true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }

        override func startLoading() {
            guard let stub = URLProtocolStub.stub else { return }
            if let data = stub.data {
                client?.urlProtocol(self, didLoad: data)
            }
            if let response = stub.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            }

            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }
}
