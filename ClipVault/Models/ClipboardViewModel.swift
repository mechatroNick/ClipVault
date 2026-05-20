//
//  ClipboardViewModel.swift
//  ClipVault
//

import Foundation
import Observation
import GRDB
import Combine
import AppKit

@Observable
@MainActor
final class ClipboardViewModel {
    let repository: ClipboardRepository
    private let pasteService: PasteService
    
    var entries: [ClipboardEntry] = []
    var searchQuery: String = "" {
        didSet {
            searchSubject.send(searchQuery)
        }
    }
    var selectedIndex: Int? = nil
    var activeHash: String? = nil
    var isLoading = false
    
    private var hasMoreEntries = true
    private let pageSize = 50
    private let searchSubject = PassthroughSubject<String, Never>()
    private var searchCancellable: AnyCancellable?
    private var observationTask: Task<Void, Never>?

    init(repository: ClipboardRepository = ClipboardRepository(), pasteService: PasteService = PasteService()) {
        self.repository = repository
        self.pasteService = pasteService
        setupObservation()
        setupSearchDebounce()
    }

    private func setupSearchDebounce() {
        searchCancellable = searchSubject
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateObservation()
            }
    }
    
    func moveSelection(direction: Int) {
        guard !entries.isEmpty else { return }
        
        if let current = selectedIndex {
            let next = current + direction
            if next >= 0 && next < entries.count {
                selectedIndex = next
            } else if next < 0 {
                selectedIndex = entries.count - 1
            } else {
                selectedIndex = 0
            }
        } else {
            selectedIndex = direction > 0 ? 0 : entries.count - 1
        }
    }
    
    func deleteEntry(at index: Int) {
        guard index >= 0 && index < entries.count else { return }
        let entry = entries[index]
        if let id = entry.id {
            try? repository.delete(id: id)
        }
    }
    
    func togglePin(at index: Int) {
        guard index >= 0 && index < entries.count else { return }
        let entry = entries[index]
        if let id = entry.id {
            if entry.isPinned {
                try? repository.unpin(id: id)
            } else {
                try? repository.pin(id: id)
            }
        }
    }

    func copyEntry(at index: Int) {
        guard index >= 0 && index < entries.count else { return }
        let entry = entries[index]
        Task {
            do {
                let decrypted = try repository.decryptContent(for: entry)
                try await pasteService.preparePasteboard(for: decrypted)
                activeHash = entry.contentHash
            } catch {
                print("Failed to copy entry: \(error)")
            }
        }
    }

    func refreshActiveHash() {
        let pb = NSPasteboard.general
        var plainText: Data? = nil
        if let s = pb.string(forType: .string) { plainText = Data(s.utf8) }
        let richText = pb.data(forType: .rtf) ?? pb.data(forType: .html)
        let imageData = pb.data(forType: .tiff) ?? pb.data(forType: .png)
        
        activeHash = ClipboardEntry.calculateHash(plainText: plainText, richText: richText, imageData: imageData)
    }

    func loadMoreEntries() {
        guard !isLoading && hasMoreEntries else { return }
        isLoading = true
        
        Task {
            do {
                let newEntries: [ClipboardEntry]
                if searchQuery.isEmpty {
                    newEntries = try repository.fetchEntries(limit: pageSize, offset: entries.count)
                } else {
                    newEntries = try repository.search(searchQuery, limit: pageSize, offset: entries.count)
                }
                
                if newEntries.count < pageSize {
                    hasMoreEntries = false
                }
                self.entries.append(contentsOf: newEntries)
            } catch {
                print("Failed to load more entries: \(error)")
            }
            isLoading = false
        }
    }

    private func setupObservation() {
        observationTask?.cancel()
        observationTask = Task {
            let stream = repository.observeEntries(limit: pageSize)
            for await rawEntries in stream {
                if !Task.isCancelled {
                    if self.entries.count <= pageSize {
                        self.entries = rawEntries
                    } else {
                        // Keep current entries, but update common ones
                        for (i, entry) in rawEntries.enumerated() {
                            if i < self.entries.count {
                                self.entries[i] = entry
                            }
                        }
                    }
                    self.refreshActiveHash()
                }
            }
        }
    }

    private func updateObservation() {
        hasMoreEntries = true
        if searchQuery.isEmpty {
            setupObservation()
        } else {
            observationTask?.cancel()
            observationTask = nil
            do {
                entries = try repository.search(searchQuery, limit: pageSize)
                if entries.count < pageSize {
                    hasMoreEntries = false
                }
            } catch {
                print("Search failed: \(error)")
                entries = []
                hasMoreEntries = false
            }
        }
    }
}
