//
//  EssentialFeediOSTests.swift
//  EssentialFeediOSTests
//
//  Created by Quốc Huy Nguyễn on 8/9/24.
//

import XCTest

final class FeedViewController {
    init(loader: FeedViewControllerTests.LoaderSpy) {}
}

final class FeedViewControllerTests: XCTestCase {
    func test_init_doesNotLoadFeed() {
        let loader = LoaderSpy()
        _ = FeedViewController(loader: loader)
        XCTAssertEqual(loader.loadCallCount, 0)
    }

    class LoaderSpy {
        var loadCallCount: Int = 0
    }
}
