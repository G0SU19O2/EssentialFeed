//
//  EssentialFeediOSTests.swift
//  EssentialFeediOSTests
//
//  Created by Quốc Huy Nguyễn on 8/9/24.
//

import XCTest

final class FeedViewController: UIViewController {
    private var loader: FeedViewControllerTests.LoaderSpy?
    convenience init(loader: FeedViewControllerTests.LoaderSpy) {
        self.init()
        self.loader = loader
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loader?.load()
    }
}

final class FeedViewControllerTests: XCTestCase {
    func test_init_doesNotLoadFeed() {
        let loader = LoaderSpy()
        _ = FeedViewController(loader: loader)
        XCTAssertEqual(loader.loadCallCount, 0)
    }

    class LoaderSpy {
        var loadCallCount: Int = 0
        func load() {
            loadCallCount += 1
        }
    }
}
