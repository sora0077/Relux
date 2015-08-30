//
//  ReluxTests.swift
//  ReluxTests
//
//  Created by 林達也 on 2015/08/03.
//  Copyright © 2015年 jp.sora0077. All rights reserved.
//

import XCTest
@testable import Relux

class ReluxTests: XCTestCase {
    
    struct Action1: Action {
        typealias Payload = Int
    }
    struct Action2: Action {
        typealias Payload = Int
    }
    
    struct Store1: Store {
        
        func aaa() {
            print("bbb")
        }
    }
    struct Store2: Store {
        
        func aaa() {
            print("bbb")
        }
    }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test__dipatchの正常パターン() {
        
        var cnt = 0
        
        let dispatcher = Dispatcher(queue: dispatch_get_main_queue())
        
        dispatcher.register(Store1.self, action: Action1.self) { action, payload in
            cnt += 1
            
            do {
                let payload = try payload()
                XCTAssertEqual(payload, 1)
            } catch {
                XCTFail()
            }
        }
        
        dispatcher.dispatch(Action1(), payload: 1)
        
        XCTAssertEqual(cnt, 1)
    }
    
    func test__dipatchのErrorTypeの正常パターン() {
        
        var cnt = 0
        
        let dispatcher = Dispatcher(queue: dispatch_get_main_queue())
        
        dispatcher.register(Store1.self, action: Action1.self) { action, payload in
            cnt += 1
            
            do {
                _ = try payload()
                XCTFail()
            }
            catch _ as NSError {
                // do nothing
            }
            catch {
                XCTFail()
            }
        }
        
        dispatcher.dispatch(Action1(), error: NSError(domain: "", code: 0, userInfo: nil))
        
        XCTAssertEqual(cnt, 1)
    }
    
    func test__unregisterの正常パターン() {
        
        let dispatcher = Dispatcher(queue: dispatch_get_main_queue())
        
        dispatcher.register(Store1.self, action: Action1.self) { _ in
            
        }
        dispatcher.register(Store1.self, action: Action2.self) { _ in
        }
        
        XCTAssertEqual(dispatcher.count, 2)
        
        dispatcher.unregister(Store1.self, action: Action1.self)
        
        XCTAssertEqual(dispatcher.count, 1)
    
        Store1().aaa()
    }
    
    func test__waitForのパターン() {
        
        var cnt: Int = 0
        
        let dispatcher = Dispatcher(queue: dispatch_get_main_queue())
        
        dispatcher.register(Store2.self, action: Action1.self) { _ in
            XCTAssertEqual(cnt, 0)
            dispatcher.waitFor(Store1.self)
            XCTAssertEqual(cnt, 1)
        }
        
        dispatcher.register(Store1.self, action: Action1.self) { _ in
            cnt += 1
            XCTAssertEqual(cnt, 1)
        }
        dispatcher.dispatch(Action1(), payload: 1)
        
    }
    
    func test__waitForのパターン2() {
        
        var cnt: Int = 0
        
        let dispatcher = Dispatcher(queue: dispatch_get_main_queue())
        
        dispatcher.register(Store1.self, action: Action1.self) { _ in
            cnt += 1
            XCTAssertEqual(cnt, 1)
        }
        dispatcher.register(Store2.self, action: Action1.self) { _ in
            dispatcher.waitFor(Store1.self)
            XCTAssertEqual(cnt, 1)
        }
        
        dispatcher.dispatch(Action1(), payload: 1)
        
    }
}
