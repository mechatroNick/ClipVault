//
//  ClipboardCaptureService.swift
//  ClipVault
//
//  Created by ClipVault.
//

import AppKit

/// Orchestrates the pipeline from detecting a pasteboard change to storing an encrypted entry.
actor ClipboardCaptureService {
    private let monitor: PasteboardMonitor
    private let detector: ContentTypeDetector
    private let repository: ClipboardRepository
    private let pasteboard: PasteboardProtocol
    private let vaultManager: VaultManager
    private let settings: SettingsManager
    private let workspaceAppIdentifier: () -> String?
    
    private var streamTask: Task<Void, Never>?
    
    init(monitor: PasteboardMonitor,
         detector: ContentTypeDetector = ContentTypeDetector(),
         repository: ClipboardRepository,
         pasteboard: PasteboardProtocol = NSPasteboard.general,
         vaultManager: VaultManager = .shared,
         settings: SettingsManager = .shared,
         workspaceAppIdentifier: @escaping () -> String? = { NSWorkspace.shared.frontmostApplication?.bundleIdentifier }) {
        self.monitor = monitor
        self.detector = detector
        self.repository = repository
        self.pasteboard = pasteboard
        self.vaultManager = vaultManager
        self.settings = settings
        self.workspaceAppIdentifier = workspaceAppIdentifier
    }
    
    func start() {
        let stream = monitor.start()
        streamTask = Task {
            for await _ in stream {
                await captureCurrentPasteboard()
            }
        }
    }
    
    func stop() {
        streamTask?.cancel()
        streamTask = nil
        monitor.stop()
    }
    
    private func captureCurrentPasteboard() async {
        print("DEBUG (Service): captureCurrentPasteboard called")
        let type = detector.detectType(from: pasteboard)
        print("DEBUG (Service): detected type: \(type)")
        guard type != "unknown" else { return }
        
        var plainText: Data? = nil
        var richText: Data? = nil
        var imageData: Data? = nil
        var fileURL: String? = nil
        
        let thresholdBytes = settings.largeFileThresholdMB * 1024 * 1024
        
        if let string = pasteboard.string(forType: .string) {
            let data = Data(string.utf8)
            if data.count > thresholdBytes {
                fileURL = try? vaultManager.saveToVault(data: data, extension: "txt")
            } else {
                plainText = data
            }
        }
        
        switch type {
        case "image":
            if let tiff = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png),
               let image = NSImage(data: tiff) {
                print("DEBUG (Service): Before generateThumbnail")
                imageData = await generateThumbnail(from: image, maxDimension: 48)
                print("DEBUG (Service): After generateThumbnail")
                
                if tiff.count > thresholdBytes {
                    let ext = pasteboard.types?.contains(.png) == true ? "png" : "tiff"
                    fileURL = try? vaultManager.saveToVault(data: tiff, extension: ext)
                }
            }
        case "file":
            if let pathString = pasteboard.string(forType: .fileURL), let url = URL(string: pathString) {
                // For MVP, always store relative path for file copies in Finder.
                // Optionally could "Archive to Vault" in future logic.
                fileURL = url.path
            }
        case "rtf", "html":
            if let data = pasteboard.data(forType: .rtf) ?? pasteboard.data(forType: .html) {
                if data.count > thresholdBytes {
                    let ext = pasteboard.types?.contains(.rtf) == true ? "rtf" : "html"
                    fileURL = try? vaultManager.saveToVault(data: data, extension: ext)
                } else {
                    richText = data
                }
            }
        default:
            break
        }
        
        let sourceApp = workspaceAppIdentifier() ?? "unknown"
        let metadataString = "{\"app\":\"\(sourceApp)\"}"
        let metadata = Data(metadataString.utf8)
        
        var entry = ClipboardEntry(
            timestamp: Date(),
            contentType: type,
            plainTextContent: plainText,
            richTextContent: richText,
            imageData: imageData,
            fileURL: fileURL,
            sourceApplication: sourceApp,
            metadata: metadata
        )
        
        do {
            try repository.save(&entry)
            print("DEBUG (Service): entry saved successfully")
        } catch {
            print("DEBUG (Service): Failed to save clipboard entry: \(error)")
        }
    }
    
    @MainActor
    private func generateThumbnail(from image: NSImage, maxDimension: CGFloat) -> Data? {
        let originalSize = image.size
        let ratio = maxDimension / max(originalSize.width, originalSize.height)
        if ratio >= 1.0 {
            return image.tiffRepresentation
        }
        
        let targetSize = NSSize(width: originalSize.width * ratio, height: originalSize.height * ratio)
        let newImage = NSImage(size: targetSize, flipped: false) { rect in
            image.draw(in: rect, from: NSRect(origin: .zero, size: originalSize), operation: .sourceOver, fraction: 1.0)
            return true
        }
        
        return newImage.tiffRepresentation
    }
}
