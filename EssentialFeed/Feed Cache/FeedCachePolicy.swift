//
//  FeedCachePolicy.swift
//  EssentialFeed
//
//  Created by Quốc Huy Nguyễn on 7/20/24.
//

import Foundation

final class FeedCachePolicy {
    private init() {}
    private static let calendar = Calendar(identifier: .gregorian)
    private static var maxCacheAgeInDays: Int {
        return 7
    }

    internal static func validate(_ timestamp: Date, against date: Date) -> Bool {
        guard let maxCacheAge = FeedCachePolicy.calendar.date(byAdding: .day, value: FeedCachePolicy.maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        return date < maxCacheAge
    }
}
