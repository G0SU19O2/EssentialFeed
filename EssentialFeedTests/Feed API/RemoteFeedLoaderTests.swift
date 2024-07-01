//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Quốc Huy Nguyễn on 6/27/24.
//

import EssentialFeed
import XCTest

class RemoteFeedLoaderTests: XCTestCase {
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }

    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://google.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load(completion: { _ in })
        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_loadTwice_requestDataFromURL() {
        let url = URL(string: "https://google.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load(completion: { _ in })
        sut.load(completion: { _ in })
        XCTAssertEqual(client.requestedURLs, [url, url])
    }

    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        expect(sut, toCompleteWith: .failure(.connectivity)) {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        }
    }

    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        let samples = [199, 201, 300, 400, 500]
        for (index, sample) in samples.enumerated() {
            expect(sut, toCompleteWith: .failure(.invalidData)) {
                let json = makeItemsJSON([])
                client.complete(withStatusCode: sample, data: json, at: index)
            }
        }
    }

    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        expect(sut, toCompleteWith: .failure(.invalidData)) {
            let invalidJSON = Data("invalid JSON".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        }
    }

    func test_load_deliversNoItemOn200HTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()
        expect(sut, toCompleteWith: .success([])) {
            let emptyJSONList = makeItemsJSON([])
            client.complete(withStatusCode: 200, data: emptyJSONList)
        }
    }

    func test_load_deliversItemsOn200HTTPResponseWithJSONItems() {
        let (sut, client) = makeSUT()
        let item1 = makeItem(id: UUID(), description: "a description", location: "a location", imageURL: URL(string: "https://a-url.com")!)
        let item2 = makeItem(id: UUID(), description: nil, location: nil, imageURL: URL(string: "https://another-url.com")!)
        expect(sut, toCompleteWith: .success([item1.model, item2.model])) {
            let json = makeItemsJSON([item1.json, item2.json])
            client.complete(withStatusCode: 200, data: json)
        }
    }

    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let url = URL(string: "https://google.com")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)
        var capturedResults: [RemoteFeedLoader.Result] = []
        sut?.load { capturedResults.append($0) }
        sut = nil
        client.complete(withStatusCode: 200, data: makeItemsJSON([]))
        XCTAssertTrue(capturedResults.isEmpty)
    }

    // MARK: - Helpers

    private func makeSUT(url: URL = URL(string: "https://google.com")!, filePath: StaticString = #filePath, line: UInt = #line) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        trackForMemoryLeads(client, filePath: filePath, line: line)
        trackForMemoryLeads(sut, filePath: filePath, line: line)
        return (sut, client)
    }

    private func trackForMemoryLeads(_ instance: AnyObject, filePath: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak", file: filePath, line: line)
        }
    }

    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedItem, json: [String: Any]) {
        let item = FeedItem(id: id, description: description, location: location, imageURL: imageURL)
        let json = ["id": id.uuidString, "description": description, "location": location, "image": imageURL.absoluteString]
        return (item, json as [String: Any])
    }

    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
        let json = ["items": items]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    private func expect(_ sut: RemoteFeedLoader, toCompleteWith result: RemoteFeedLoader.Result, when action: () -> Void, filePath: StaticString = #filePath, line: UInt = #line) {
        var capturedResults: [RemoteFeedLoader.Result] = []
        sut.load { capturedResults.append($0) }
        action()
        XCTAssertEqual(capturedResults, [result], file: filePath, line: line)
    }

    class HTTPClientSpy: HTTPClient {
        var requestedURLs: [URL] {
            return messages.map { $0.url }
        }

        private var messages: [(url: URL, completion: (HTTPClientResult) -> Void)] = []
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }

        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }

        func complete(withStatusCode: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: withStatusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            messages[index].completion(.success((data, response)))
        }
    }
}
