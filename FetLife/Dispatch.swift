//
//  Dispatch.swift
//  FetLife
//
//  Created by Jose Cortinas on 3/7/16.
//  Copyright © 2016 BitLove Inc. All rights reserved.
//

import Foundation

typealias ExecutionBlock = () -> Void


struct Dispatch {
    static func delay(_ delay: Double, closure: @escaping ExecutionBlock) {
        Queue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
    static func asyncOnMainQueue(asyncBlock: @escaping ExecutionBlock) {
        executeAsynchronously(Queue.main, closure: asyncBlock)
    }
    
    static func asyncOnUserInitiatedQueue(asyncBlock: @escaping ExecutionBlock) {
        executeAsynchronously(Queue.userInitiated, closure: asyncBlock)
    }
    
    static func asyncOnUtilityQueue(asyncBlock: @escaping ExecutionBlock) {
        executeAsynchronously(Queue.utility, closure: asyncBlock)
    }
    
    static func asyncOnBackgroundQueue(asyncBlock: @escaping ExecutionBlock) {
        executeAsynchronously(Queue.background, closure: asyncBlock)
    }
    
    static func executeAsynchronously(_ serviceQueue: DispatchQueue, closure: @escaping ExecutionBlock) {
        serviceQueue.async(execute: closure)
    }
    
    struct Queue {
        static var main: DispatchQueue {
            return DispatchQueue.main
        }
        
        static var userInitiated: DispatchQueue {
            return getGlobalQueueById(qosLevel: DispatchQoS.userInitiated)
        }
        
        static var utility: DispatchQueue {
            return getGlobalQueueById(qosLevel: DispatchQoS.utility)
        }
        
        static var background: DispatchQueue {
            return getGlobalQueueById(qosLevel: DispatchQoS.background)
        }
        
        static func getGlobalQueueById(qosLevel id: DispatchQoS) -> DispatchQueue {
            return DispatchQueue.global(qos: id.qosClass)
        }
    }
}
