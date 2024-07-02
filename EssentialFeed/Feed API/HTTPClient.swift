//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Quốc Huy Nguyễn on 1/7/24.
//

import Foundation

public typealias HTTPClientResult = Result<(Data, HTTPURLResponse), Error>
public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}
