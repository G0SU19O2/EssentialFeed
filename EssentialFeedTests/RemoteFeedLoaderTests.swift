//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Quốc Huy Nguyễn on 6/27/24.
//

import Foundation
import Testing

class RemoteFeedLoader {
    var client: HTTPClient
    var url: URL
    init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    func load() {
        client.get(from: url)
    }
}

protocol HTTPClient {
    func get(from url: URL)
}

struct RemoteFeedLoaderTests {
    @Test func init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        #expect(client.requestedURL == nil)
    }

    @Test func load_requestDataFromURL() {
        let (sut, client) = makeSUT()
        sut.load()
        #expect(client.requestedURL == sut.url)
    }

    // MARK: - Helpers

    private func makeSUT(url: URL = URL(string: "https://google.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }

    class HTTPClientSpy: HTTPClient {
        var requestedURL: URL?

        func get(from url: URL) {
            requestedURL = url
        }
    }
}
