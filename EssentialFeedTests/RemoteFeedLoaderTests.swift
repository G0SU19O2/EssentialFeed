//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Quốc Huy Nguyễn on 6/27/24.
//

import Foundation
import Testing

class RemoteFeedLoader {
    
}

class HTTPClient {
    var requestedURL: URL?
}

struct RemoteFeedLoaderTests {
    @Test func init_doesNotRequestDataFromURL() {
        let client = HTTPClient()
        _ = RemoteFeedLoader()
        #expect(client.requestedURL == nil)
    }
}
