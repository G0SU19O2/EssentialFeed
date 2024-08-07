//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Quốc Huy Nguyễn on 6/27/24.
//

import Foundation

public typealias LoadFeedResult = Result<[FeedImage], Error>

public protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
