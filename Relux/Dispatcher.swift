//
//  Dispatcher.swift
//  Relux
//
//  Created by 林達也 on 2015/08/03.
//  Copyright © 2015年 jp.sora0077. All rights reserved.
//

import Foundation

private func sync_if_main_queue(queue: dispatch_queue_t!, _ block: dispatch_block_t) {
    
    let main = dispatch_get_main_queue()
    if main === queue {
        if NSThread.isMainThread() {
            block()
        } else {
            dispatch_sync(main, block)
        }
    } else {
        dispatch_async(queue, block)
    }
}

public final class Dispatcher {
    
    typealias StoreIdentifier = String
    typealias ActionIdentifier = String
    
    let queue: dispatch_queue_t
    
    var dispatching: Bool = false
    
    var callbacks: [StoreIdentifier: [ActionIdentifier: (Any, Any)]] = [:]
    
    var count: Int {
        var sum: Int = 0
        for values in callbacks.values {
            sum += values.count
        }
        return sum
    }
    
    var pending: [StoreIdentifier: [Deliver]] = [:]
    
    init(queue: dispatch_queue_t = dispatch_queue_create("jp.sora0077.dispatcher.queue", DISPATCH_QUEUE_SERIAL)) {
        self.queue = queue
    }
}

extension Dispatcher {
    
    func startDispatching() {
        
        assert(!dispatching, "")
        
        pending.removeAll()
        dispatching = true
    }
    
    func stopDispatching() {
        
        dispatching = false
    }
}

public extension Dispatcher {
    
    func dispatch<A: Action>(action: A, payload: A.Payload) {
        
        sync_if_main_queue(queue) {
            self.startDispatching()
            for (storeKey, values) in self.callbacks {
                for (_, (actionType, callback)) in values {
                    if  let _ = actionType as? A.Type,
                        let callback = callback as? (A, () throws -> A.Payload) -> Void
                    {
                        if self.pending[storeKey] == nil {
                            self.pending[storeKey] = []
                        }
                        self.pending[storeKey]?.append(Deliver {
                            callback(action) { payload }
                        })
                    }
                }
            }
            for key in self.pending.keys {
                if let blocks = self.pending[key] {
                    for block in blocks {
                        block.run()
                    }
                    self.pending.removeValueForKey(key)
                }
            }
            self.stopDispatching()
        }
    }
    
    func dispatch<A: Action>(action: A, error: ErrorType) {
        
        sync_if_main_queue(queue) {
            self.startDispatching()
            for (storeKey, values) in self.callbacks {
                for (_, (actionType, callback)) in values {
                    if  let _ = actionType as? A.Type,
                        let callback = callback as? (A, () throws -> A.Payload) -> Void
                    {
                        if self.pending[storeKey] == nil {
                            self.pending[storeKey] = []
                        }
                        self.pending[storeKey]?.append(Deliver {
                            callback(action) { throw error }
                        })
                    }
                }
            }
            for key in self.pending.keys {
                if let blocks = self.pending[key] {
                    for block in blocks {
                        block.run()
                    }
                    self.pending.removeValueForKey(key)
                }
            }
            self.stopDispatching()
        }
    }
    
    func register<A: Action, S: Store>(store: S.Type, action: A.Type, _ callback: (A, () throws -> A.Payload) -> Void) {
        
        let storeKey = "\(Mirror(reflecting: store))"
        let actionKey = "\(Mirror(reflecting: action))"
        if callbacks[storeKey] == nil {
            callbacks[storeKey] = [:]
        }
        callbacks[storeKey]?[actionKey] = (action, callback)
    }
    
    func unregister<A: Action, S: Store>(store: S.Type, action: A.Type) {
        
        let storeKey = "\(Mirror(reflecting: store))"
        let actionKey = "\(Mirror(reflecting: action))"
        callbacks[storeKey]?.removeValueForKey(actionKey)
    }
    
    func waitFor<S: Store>(store: S.Type) {
        
        assert(dispatching, "")
        
        let storeKey = "\(Mirror(reflecting: store))"
        
        if let blocks = pending[storeKey] {
            for block in blocks {
                block.run()
            }
            pending.removeValueForKey(storeKey)
        }
    }
}


final class Deliver {
    
    private let block: () -> Void
    private var handled: Bool = false
    
    init(_ block: () -> Void) {
        self.block = block
    }
    
    func run() {
        
        if handled {
            return
        }
        handled = true
        block()
    }
}

