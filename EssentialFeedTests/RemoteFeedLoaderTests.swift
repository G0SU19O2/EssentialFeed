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

class HTTPClientSpy: HTTPClient {
    var requestedURL: URL?

    func get(from url: URL) {
        requestedURL = url
    }
}

struct RemoteFeedLoaderTests {
    @Test func init_doesNotRequestDataFromURL() {
        let client = HTTPClientSpy()
        let url = URL(string: "https://google.com")!
        _ = RemoteFeedLoader(url: url, client: client)
        #expect(client.requestedURL == nil)
    }

    @Test func load_requestDataFromURL() {
        let client = HTTPClientSpy()
        let url = URL(string: "https://google.com")!
        let sut = RemoteFeedLoader(url: url, client: client)
        sut.load()
        #expect(client.requestedURL == url)
    }
}
