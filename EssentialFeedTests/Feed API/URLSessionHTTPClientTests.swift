//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Quốc Huy Nguyễn on 2/7/24.
//

import Foundation
import XCTest

class URLSessionHTTPClient {
    var session: URLSession
    init(session: URLSession) {
        self.session = session
    }
    func get(from url: URL) {
        session.dataTask(with: url) {_,_,_ in }
    }
}
class URLSessionHTTPClientTests: XCTestCase {
    func test_getFromURL_createDataTaskWithURL() {
        let url = URL(string: "https://google.com")!
        let session = URLSessionSpy()
        let sut = URLSessionHTTPClient(session: session)
        sut.get(from: url)
        XCTAssertEqual(session.receivedURLs, [url])
    }
    
    class URLSessionSpy: URLSession {
        var receivedURLs = [URL]()
        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, (any Error)?) -> Void) -> URLSessionDataTask {
            receivedURLs.append(url)
            return FakeURLSessionDataTask()
        }
    }
    
    class FakeURLSessionDataTask: URLSessionDataTask {
        
    }
}
