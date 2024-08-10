//
//  EssentialFeediOSTests.swift
//  EssentialFeediOSTests
//
//  Created by Quốc Huy Nguyễn on 8/9/24.
//

import EssentialFeed
import XCTest

final class FeedViewController: UIViewController {
    private var loader: FeedLoader?
    convenience init(loader: FeedLoader) {
        self.init()
        self.loader = loader
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loader?.load(completion: { _ in

        })
    }
}

final class FeedViewControllerTests: XCTestCase {
    func test_init_doesNotLoadFeed() {
        let (_, loader) = makeSUT()
        XCTAssertEqual(loader.loadCallCount, 0)
    }

    func test_viewDidLoad_loadsFeed() {
        let (sut, loader) = makeSUT()
        sut.viewDidLoad()
        XCTAssertEqual(loader.loadCallCount, 1)
    }

    class LoaderSpy: FeedLoader {
        func load(completion: @escaping (EssentialFeed.LoadFeedResult) -> Void) {
            loadCallCount += 1
        }

        var loadCallCount: Int = 0
    }

    // MARK: - Helpers

    private func makeSUT(filePath: StaticString = #filePath, line: UInt = #line) -> (sut: FeedViewController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        trackForMemoryLeaks(loader, filePath: filePath, line: line)
        trackForMemoryLeaks(sut, filePath: filePath, line: line)
        return (sut, loader)
    }
}
