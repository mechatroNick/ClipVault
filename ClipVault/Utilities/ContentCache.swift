//
//  ContentCache.swift
//  ClipVault
//

import Foundation

/// A thread-safe in-memory cache for decrypted clipboard content.
///
/// Prevents redundant decryptions of large text/Markdown/HTML strings while scrolling.
final class ContentCache {
    static let shared = ContentCache()
    
    private let cache = NSCache<NSString, EntryWrapper>()
    
    private final class EntryWrapper {
        let entry: ClipboardEntry
        init(_ entry: ClipboardEntry) { self.entry = entry }
    }
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 20 * 1024 * 1024 // 20 MB
    }
    
    func get(for id: Int64) -> ClipboardEntry? {
        return cache.object(forKey: "\(id)" as NSString)?.entry
    }
    
    func set(_ entry: ClipboardEntry, for id: Int64) {
        cache.setObject(EntryWrapper(entry), forKey: "\(id)" as NSString)
    }
    
    func clear() {
        cache.removeAllObjects()
    }
}
