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
        session.dataTask(with: url) { _, _, error in
            if let error {
                completion(.failure(error))
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
        let error = NSError(domain: "any error", code: 1)
        let capturedError: NSError? = resultErrorFor(data: nil, response: nil, error: error) as? NSError
        XCTAssertEqual(error.code, capturedError?.code)
        XCTAssertEqual(error.domain, capturedError?.domain)
    }

    func test_getFromURL_failsAllNilValue() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
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
            case .failure(let error):
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

    private class URLProtocolStub: URLProtocol {
        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }

        static func stub(data: Data?, response: URLResponse?, error: Error? = nil) {
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
