//
//  XCTestCase+MemoryLeakTracking.swift
//  EssentialFeedTests
//
//  Created by Quốc Huy Nguyễn on 7/4/24.
//

import Foundation
import XCTest

extension XCTestCase {
    func trackForMemoryLeads(_ instance: AnyObject, filePath: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak", file: filePath, line: line)
        }
    }
}
