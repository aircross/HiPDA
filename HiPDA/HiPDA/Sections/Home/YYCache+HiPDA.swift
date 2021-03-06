//
//  YYCache+HiPDA.swift
//  HiPDA
//
//  Created by leizh007 on 2017/5/5.
//  Copyright © 2017年 HiPDA. All rights reserved.
//

import Foundation
import YYCache
import Argo
import HandyJSON

// MARK: - Associated Object
private var kTidsKey: Void?
private var kLRUKey: Void?
private var kLockKey: Void?

extension YYCache {
    /// 帖子id的数组，0到N-1按时间从近到远
    var tids: [Int] {
        get {
            lock?.lock()
            defer {
                lock?.unlock()
            }
            return objc_getAssociatedObject(self, &kTidsKey) as? [Int] ?? []
        }
        
        set {
            lock?.lock()
            defer {
                lock?.unlock()
            }
            objc_setAssociatedObject(self, &kTidsKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// tids是否使用LRU策略
    var useLRUStrategy: Bool {
        get {
            return objc_getAssociatedObject(self, &kLRUKey) as? Bool ?? false
        }
        
        set {
            objc_setAssociatedObject(self, &kLRUKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var lock: NSRecursiveLock? {
        get {
            return objc_getAssociatedObject(self, &kLockKey) as? NSRecursiveLock
        }
        
        set {
            objc_setAssociatedObject(self, &kLockKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 是否包含帖子
    ///
    /// - Parameter thread: 帖子
    /// - Returns: 包含返回true，否则返回false
    func containsThread(_ thread: HiPDA.Thread) -> Bool {
        return containsObject(forKey: "\(thread.id)")
    }
    
    /// 根据id查找帖子
    ///
    /// - Parameter id: 帖子id
    /// - Returns: 找到帖子返回，否则返回nil
    func thread(for id: Int) -> HiPDA.Thread? {
        guard let threadString = object(forKey: "\(id)") as? String,
            let threadData = threadString.data(using: .utf8),
            let attributes = try? JSONSerialization.jsonObject(with: threadData, options: []),
            let thread = try? HiPDA.Thread.decode(JSON(attributes)).dematerialize() else {
                return nil
        }
        return thread
    }
    
    /// 添加帖子
    ///
    /// - Parameter thread: 帖子
    func addThread(_ thread: HiPDA.Thread) {
        if let index = tids.index(of: thread.id) {
            if useLRUStrategy {
                tids.insert(tids.remove(at: index), at: 0)
            }
        } else {
            tids.insert(thread.id, at: 0)
        }
        while tids.count > Int(memoryCache.countLimit) {
            if let tid = tids.last {
                removeObject(forKey: "\(tid)")
            }
            tids.removeLast()
        }
        let threadString = thread.encode()
        setObject(threadString as NSString, forKey: "\(thread.id)")
    }
    
    /// 移除帖子
    ///
    /// - Parameter thread: 帖子
    func removeThread(_ thread: HiPDA.Thread) {
        tids = tids.filter { $0 != thread.id }
        removeObject(forKey: "\(thread.id)")
    }
    
    /// 清空缓存
    func clear() {
        tids = []
        removeAllObjects()
    }
    
    /// 获取帖子帖子列表
    ///
    /// - Parameters:
    ///   - fid: 论坛版块id
    ///   - typeid: 论坛版块子id
    /// - Returns: 论坛版块帖子列表
    func threads(forFid fid: Int, typeid: Int) -> [HiPDA.Thread]? {
        let key = "fid=\(fid)&typeid=\(typeid)"
        guard let threadsString = object(forKey: key) as? String,
            let threadsData = threadsString.data(using: .utf8),
            let data = try? JSONSerialization.jsonObject(with: threadsData, options: []),
            let arr = data as? NSArray else {
                return nil
        }
        
        return arr.flatMap {
            return try? HiPDA.Thread.decode(JSON($0)).dematerialize()
        }
    }
    
    /// 添加论坛帖子帖子列表
    ///
    /// - Parameters:
    ///   - threads: 帖子列表
    ///   - fid: 论坛版块id
    ///   - typeid: 论坛版块帖子列表
    func setThreads(threads: [HiPDA.Thread], forFid fid: Int, typeid: Int) {
        let key = "fid=\(fid)&typeid=\(typeid)"
        let threadsString = JSONSerializer.serializeToJSON(object: threads) ?? ""
        setObject(threadsString as NSString, forKey: key)
    }
}
