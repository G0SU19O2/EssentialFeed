//
//  EssentialFeediOSTests.swift
//  EssentialFeediOSTests
//
//  Created by Quốc Huy Nguyễn on 8/9/24.
//

import EssentialFeed
import XCTest

final class FeedViewController: UITableViewController {
    private var loader: FeedLoader?

    convenience init(loader: FeedLoader) {
        self.init()
        self.loader = loader
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
        refreshControl?.beginRefreshing()
        load()
    }

    @objc private func load() {
        loader?.load { [weak self] _ in
            self?.refreshControl?.endRefreshing()
        }
    }
}

final class FeedViewControllerTests: XCTestCase {
    func test_init_doesNotLoadFeed() {
        let (_, loader) = makeSUT()
        XCTAssertEqual(loader.loadCallCount, 0)
    }

    func test_viewDidLoad_loadsFeed() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()

        XCTAssertEqual(loader.loadCallCount, 1)
    }

    func test_pullToRefresh_loadsFeed() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        sut.refreshControl?.simulatePullToRefresh()
        XCTAssertEqual(loader.loadCallCount, 2)
        sut.refreshControl?.simulatePullToRefresh()
        XCTAssertEqual(loader.loadCallCount, 3)
    }

    func test_viewDidLoad_doNotShowsLoadingIndicator() {
        let (sut, _) = makeSUT()
        sut.loadViewIfNeeded()
        // iOS 17
        XCTAssertEqual(sut.refreshControl?.isRefreshing, false)
    }

    func test_viewDidLoad_hidesLoadingIndicatorOnLoaderCompletion() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.completeFeedLoading()
        XCTAssertEqual(sut.refreshControl?.isRefreshing, false)
    }

    func test_pullToRefresh_showsLoadingIndicator() {
        let (sut, _) = makeSUT()
        sut.replaceRefreshControlWithFakeForiOS17Support()
        sut.refreshControl?.beginRefreshing()
        XCTAssertEqual(sut.refreshControl?.isRefreshing, true)
    }

    class LoaderSpy: FeedLoader {
        private(set) var loadCallCount: Int = 0
        private var completions = [(EssentialFeed.LoadFeedResult) -> Void]()
        func load(completion: @escaping (EssentialFeed.LoadFeedResult) -> Void) {
            loadCallCount += 1
            completions.append(completion)
        }

        func completeFeedLoading() {
            completions[0](.success([]))
        }
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

private extension UIRefreshControl {
    func simulatePullToRefresh() {
        for target in allTargets {
            actions(forTarget: target, forControlEvent: .valueChanged)?.forEach {
                (target as NSObject).perform(Selector($0))
            }
        }
    }
}
private extension FeedViewController {
    func replaceRefreshControlWithFakeForiOS17Support() {
        let fake = FakeRefreshControl()
        refreshControl?.allTargets.forEach({ target in
            refreshControl?.actions(forTarget: target, forControlEvent: .valueChanged)?.forEach({ action in
                fake.addTarget(target, action: Selector(action), for: .valueChanged)
            })
        })
        refreshControl = fake
    }
}
private class FakeRefreshControl: UIRefreshControl {
    private var _isRefreshing = false
    override var isRefreshing: Bool { return _isRefreshing }
    override func beginRefreshing() {
        _isRefreshing = true
    }

    override func endRefreshing() {
        _isRefreshing = false
    }
}
