//
//  CoreDataFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Quốc Huy Nguyễn on 8/1/24.
//

import EssentialFeed
import XCTest
class CoreDataFeedStoreTests: XCTestCase, FeedStoreSpecs {
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
    }
    
    func test_insert_deliversNoErrorOnEmptyCache() {}
    
    func test_insert_deliversNoErrorOnNonEmptyCache() {}
    
    func test_insert_overridesPreviouslyInsertedCacheValues() {}
    
    func test_delete_deliversNoErrorOnEmptyCache() {}
    
    func test_delete_hasNoSideEffectsOnEmptyCache() {}
    
    func test_delete_deliversNoErrorOnNonEmptyCache() {}
    
    func test_delete_emptiesPreviouslyInsertedCache() {}
    
    func test_storeSideEffects_runSerially() {}
    
    // MARK: - Helpers

    private func makeSUT(storeURL: URL? = nil, filePath: StaticString = #filePath, line: UInt = #line) -> FeedStore {
        let storeURL = URL(fileURLWithPath: "/dev/null")
        let storeBundle = Bundle(for: CoreDataFeedStore.self)
        let sut = try! CoreDataFeedStore(storeURL: storeURL, bundle: storeBundle)
        trackForMemoryLeads(sut)
        return sut
    }
}
