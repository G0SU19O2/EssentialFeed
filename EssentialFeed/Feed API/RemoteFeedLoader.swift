//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Quốc Huy Nguyễn on 6/27/24.
//

import Foundation

public final class RemoteFeedLoader {
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    private let client: HTTPClient
    private let url: URL
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func load(completion: @escaping (Error) -> Void) {
        client.get(from: url) { _, response in
            if response != nil {
                completion(.invalidData)
            } else {
                completion(.connectivity)
            }
        }
    }
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (Error?, HTTPURLResponse?) -> Void)
}
