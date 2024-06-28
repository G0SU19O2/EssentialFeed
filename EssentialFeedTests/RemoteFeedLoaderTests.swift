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
        sut.load()
        #expect(client.requestedURLs == [url])
    }

    @Test func loadTwice_requestDataFromURL() {
        let url = URL(string: "https://google.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load()
        sut.load()
        #expect(client.requestedURLs == [url, url])
    }

    @Test func load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        var expectedErrors: [RemoteFeedLoader.Error] = []
        sut.load {
            expectedErrors.append($0)
        }
        let clientError = NSError(domain: "Test", code: 0)
        client.complete(with: clientError)
        #expect(expectedErrors == [.connectivity])
    }

    // MARK: - Helpers

    private func makeSUT(url: URL = URL(string: "https://google.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }

    class HTTPClientSpy: HTTPClient {
        var requestedURLs: [URL] = []
        var completions: [(Error) -> Void] = []
        func get(from url: URL, completion: @escaping (Error) -> Void) {
            completions.append(completion)
            requestedURLs.append(url)
        }
        
        func complete(with error: Error, at index: Int = 0) {
            completions[index](error)
        }
    }
}
