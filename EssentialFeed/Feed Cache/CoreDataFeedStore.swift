//
//  CoreDataFeedStore.swift
//  EssentialFeed
//
//  Created by Quốc Huy Nguyễn on 8/1/24.
//

import Foundation

public class CoreDataFeedStore: FeedStore {
    public init() {}

    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {}

    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {}

    public func retrieve(completion: @escaping RetrievalCompletion) {
        completion(.empty)
    }
}
