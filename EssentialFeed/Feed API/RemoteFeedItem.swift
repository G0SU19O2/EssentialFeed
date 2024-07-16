//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Quốc Huy Nguyễn on 7/16/24.
//

import Foundation

struct RemoteFeedItem: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
}
