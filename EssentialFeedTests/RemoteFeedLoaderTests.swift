//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Quốc Huy Nguyễn on 6/27/24.
//

import EssentialFeed
import Testing

struct RemoteFeedLoaderTests {
    @Test func init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        #expect(client.requestedURLs.isEmpty)
    }

    @Test func load_requestsDataFromURL() {
        let url = URL(string: "https://google.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load(completion: { _ in })
        #expect(client.requestedURLs == [url])
    }

    @Test func loadTwice_requestDataFromURL() {
        let url = URL(string: "https://google.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load(completion: { _ in })
        sut.load(completion: { _ in })
        #expect(client.requestedURLs == [url, url])
    }

    @Test func load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        expect(sut, toCompleteWith: .failure(.connectivity)) {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        }
    }

    @Test func load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        let samples = [199, 201, 300, 400, 500]
        for (index, sample) in samples.enumerated() {
            expect(sut, toCompleteWith: .failure(.invalidData)) {
                client.complete(withStatusCode: sample, at: index)
            }
        }
    }

    @Test func load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        expect(sut, toCompleteWith: .failure(.invalidData)) {
            let invalidJSON = Data("invalid JSON".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        }
    }

    @Test func load_deliversNoItemOn200HTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()
        expect(sut, toCompleteWith: .success([])) {
            let emptyJSONList = Data("{\"items\": []}".utf8)
            client.complete(withStatusCode: 200, data: emptyJSONList)
        }
    }

    // MARK: - Helpers

    private func makeSUT(url: URL = URL(string: "https://google.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }

    private func expect(_ sut: RemoteFeedLoader, toCompleteWith result: RemoteFeedLoader.Result, when action: () -> Void, filePath: String = #filePath, line: Int = #line) {
        var capturedResults: [RemoteFeedLoader.Result] = []
        sut.load { capturedResults.append($0) }
        action()
        #expect(capturedResults == [result], sourceLocation: SourceLocation(filePath: filePath, line: line))
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

        func complete(withStatusCode: Int, data: Data = Data(), at index: Int = 0) {
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
