//
//  CodableFeedStore.swift
//  EssentialFeed
//
//  Created by Quốc Huy Nguyễn on 7/26/24.
//

import Foundation

public class CodableFeedStore: FeedStore {
    public init(storeURL: URL) {
        self.storeURL = storeURL
    }

    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date
        var localFeed: [LocalFeedImage] {
            return feed.map { $0.local }
        }
    }

    private struct CodableFeedImage: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL

        init(_ image: LocalFeedImage) {
            id = image.id
            description = image.description
            location = image.location
            url = image.url
        }

        var local: LocalFeedImage {
            return LocalFeedImage(id: id, description: description, location: location, url: url)
        }
    }

    private let storeURL: URL

    public func retrieve(completion: @escaping RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            completion(.empty)
            return
        }
        do {
            let decoder = JSONDecoder()
            let cache = try decoder.decode(Cache.self, from: data)
            completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
        } catch {
            completion(.failure(error))
        }
    }

    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        let encoder = JSONEncoder()
        let cache = Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp)
        do {
            let encoded = try encoder.encode(cache)
            try encoded.write(to: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }

    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        guard FileManager.default.fileExists(atPath: storeURL.path(percentEncoded: false)) else {
            completion(nil)
            return
        }
        do {
            try FileManager.default.removeItem(at: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }
}
