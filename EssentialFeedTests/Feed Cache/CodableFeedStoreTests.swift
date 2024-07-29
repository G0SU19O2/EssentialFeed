//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Quốc Huy Nguyễn on 7/22/24.
//

import EssentialFeed
import XCTest

final class CodableFeedStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()

        setupEmptyStoreState()
    }

    override func tearDown() {
        super.tearDown()

        undoStoreSideEffects()
    }

    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        let exp = expectation(description: "Wait fo cache retrieval")
        sut.retrieve { result in
            switch result {
            case .empty:
                break
            default:
                XCTFail("Expected empty result, got \(result) instead")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }

    func test_retrieve_hasNoSideEffectsOnemptyCache() {
        let sut = makeSUT()
        expect(sut, toRetrieve: .empty)
    }

    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        insert((feed, timestamp), to: sut)
        expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        insert((feed, timestamp), to: sut)
        expect(sut, toRetrieveTwice: .found(feed: feed, timestamp: timestamp))
    }

    func test_retrieve_deliversFailureOnRetrievalError() {
        let sut = makeSUT()
        let storeURL = testSpecificStoreURL()
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        expect(sut, toRetrieve: .failure(anyNSError()))
    }

    func test_retrieve_hasNoSideEffectsOnFailure() {
        let sut = makeSUT()
        let storeURL = testSpecificStoreURL()
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        expect(sut, toRetrieveTwice: .failure(anyNSError()))
    }

    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeSUT()

        let firstInsertionError = insert((uniqueImageFeed().local, Date()), to: sut)
        XCTAssertNil(firstInsertionError, "Expected to insert cache successfully")

        let latestFeed = uniqueImageFeed().local
        let latestTimestamp = Date()
        let latestInsertionError = insert((latestFeed, latestTimestamp), to: sut)
        XCTAssertNil(latestInsertionError, "Expected to insert cache successfully")
        expect(sut, toRetrieve: .found(feed: latestFeed, timestamp: latestTimestamp))
    }

    func test_deliversErrorOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidStoreURL)
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        let insertionError = insert((feed, timestamp), to: sut)
        XCTAssertNotNil(insertionError, "Expected cache insertion to fail with an error")
        expect(sut, toRetrieve: .empty)
    }

    func test_delete_hasNoSizeEffectsOnEmptyCache() {
        let sut = makeSUT()
        let deletionError = deleteCache(from: sut)
        XCTAssertNil(deletionError, "Expected empty cache deletion to succeed")
        expect(sut, toRetrieve: .empty)
    }

    func test_delete_emptiesPreviousInsertedCache() {
        let sut = makeSUT()
        insert((uniqueImageFeed().local, Date()), to: sut)
        let deletionError = deleteCache(from: sut)
        XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed")
        expect(sut, toRetrieve: .empty)
    }

    func test_delete_deliversErrorOnDeletionError() {
        let noDeletePermissionURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletePermissionURL)
        let deletionError = deleteCache(from: sut)
        XCTAssertNotNil(deletionError, "Expected cache deletion to fail")
        expect(sut, toRetrieve: .empty)
    }

    func test_storeSideEffects_runSerially() {
        let sut = makeSUT()
        var completedOperationsInOrder = [XCTestExpectation]()

        let op1 = expectation(description: "Operation 1")
        sut.insert(uniqueImageFeed().local, timestamp: Date()) { _ in
            op1.fulfill()
            completedOperationsInOrder.append(op1)
        }

        let op2 = expectation(description: "Operation 2")
        sut.deleteCachedFeed { _ in
            op2.fulfill()
            completedOperationsInOrder.append(op2)
        }

        let op3 = expectation(description: "Operation 3")
        sut.insert(uniqueImageFeed().local, timestamp: Date()) { _ in
            op3.fulfill()
            completedOperationsInOrder.append(op3)
        }
        waitForExpectations(timeout: 5)
        XCTAssertEqual(completedOperationsInOrder, [op1, op2, op3], "Expected side-effects to run serially but operations finished in the wrong order")
    }

    // MARK: - Helpers

    @discardableResult
    private func deleteCache(from sut: FeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache deletion")
        var deletionError: Error?
        sut.deleteCachedFeed { error in
            deletionError = error
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
        return deletionError
    }

    private func expect(_ sut: FeedStore, toRetrieve expectedResult: RetrieveCachedFeedResult, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait fo cache retrieval")
        sut.retrieve { retrievedResult in
            switch (expectedResult, retrievedResult) {
            case (.empty, .empty), (.failure, .failure):
                break
            case (.found(let firstFeed, let firstTimestamp), .found(let secondFeed, let secondTimestamp)):
                XCTAssertEqual(firstFeed, secondFeed)
                XCTAssertEqual(firstTimestamp, secondTimestamp)
            default:
                XCTFail("Expected to retrieve \(expectedResult), got \(retrievedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }

    @discardableResult
    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: FeedStore) -> Error? {
        let exp = expectation(description: "Wait fo cache insertion")
        var insertionError: Error?
        sut.insert(cache.feed, timestamp: cache.timestamp) { receivedInsertionError in
            insertionError = receivedInsertionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
        return insertionError
    }

    private func expect(_ sut: FeedStore, toRetrieveTwice expectedResult: RetrieveCachedFeedResult, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: expectedResult)
        expect(sut, toRetrieve: expectedResult)
    }

    private func makeSUT(storeURL: URL? = nil, filePath: StaticString = #filePath, line: UInt = #line) -> FeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL())
        trackForMemoryLeads(sut)
        return sut
    }

    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }

    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }

    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }

    private func testSpecificStoreURL() -> URL {
        return cachesDirectory().appendingPathComponent("\(type(of: self)).store")
    }

    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
}
