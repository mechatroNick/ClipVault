//
//  ThumbnailCache.swift
//  ClipVault
//

import AppKit

/// A thread-safe in-memory cache for entry thumbnails.
///
/// Prevents expensive re-decryption and image processing when scrolling through the history list.
final class ThumbnailCache {
    static let shared = ThumbnailCache()
    
    private let cache = NSCache<NSString, NSImage>()
    
    private init() {
        cache.countLimit = 200
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }
    
    func get(for id: Int64) -> NSImage? {
        return cache.object(forKey: "\(id)" as NSString)
    }
    
    func set(_ image: NSImage, for id: Int64) {
        cache.setObject(image, forKey: "\(id)" as NSString)
    }
    
    func clear() {
        cache.removeAllObjects()
    }
}
