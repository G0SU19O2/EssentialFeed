//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Quốc Huy Nguyễn on 7/12/24.
//

import EssentialFeed
import XCTest

class CacheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertTrue(store.receivedMessages.isEmpty)
    }

    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        sut.save(uniqueImageFeed().models, completion: { _ in })
        XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed])
    }

    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()
        sut.save(uniqueImageFeed().models, completion: { _ in })
        store.completeDeletion(with: deletionError)
        XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed])
    }

    func test_save_requestNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let items = uniqueImageFeed()
        sut.save(items.models, completion: { _ in })
        store.completeDeletionSuccessfully()
        XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed, .insert(items.local, timestamp)])
    }

    func test_save_failsOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()
        expect(sut, toCompletionWithError: deletionError) {
            store.completeDeletion(with: deletionError)
        }
    }

    func test_save_failsOnInsertionError() {
        let (sut, store) = makeSUT()
        let insertionError = anyNSError()
        expect(sut, toCompletionWithError: insertionError) {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        }
    }

    func test_save_succeedOnSuccessfulCacheInsertion() {
        let (sut, store) = makeSUT()
        expect(sut, toCompletionWithError: nil) {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        }
    }

    func test_save_doesNotDeliverDeletionErrorAfterSUTInstanceHasBeenDeallocated() {
        var (sut, store): (LocalFeedLoader?, FeedStoreSpy) = makeSUT()
        var receivedErrors = [LocalFeedLoader.SaveResult]()
        sut?.save(uniqueImageFeed().models) {
            receivedErrors.append($0)
        }
        sut = nil
        store.completeDeletion(with: anyNSError())
        XCTAssertTrue(receivedErrors.isEmpty)
    }

    func test_save_doesNotDeliverInsertionErrorAfterSUTInstanceHasBeenDeallocated() {
        var (sut, store): (LocalFeedLoader?, FeedStoreSpy) = makeSUT()
        var receivedErrors = [LocalFeedLoader.SaveResult]()
        sut?.save(uniqueImageFeed().models) {
            receivedErrors.append($0)
        }
        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertion(with: anyNSError())
        XCTAssertTrue(receivedErrors.isEmpty)
    }

    // MARK: - Helpers

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, filePath: StaticString = #filePath, line: UInt = #line) -> (LocalFeedLoader, FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store)
        trackForMemoryLeaks(sut)
        return (sut, store)
    }

    private func expect(_ sut: LocalFeedLoader, toCompletionWithError expectedError: NSError?, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for save completion")
        var receivedError: Error?
        sut.save([uniqueImage()]) { error in
            receivedError = error
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1)
        XCTAssertEqual(expectedError, receivedError as? NSError)
    }
}
