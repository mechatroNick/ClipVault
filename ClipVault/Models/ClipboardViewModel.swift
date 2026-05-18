//
//  ClipboardViewModel.swift
//  ClipVault
//

import Foundation
import Observation
import GRDB

@Observable
@MainActor
final class ClipboardViewModel {
    let repository: ClipboardRepository
    
    var entries: [ClipboardEntry] = []
    var searchQuery: String = "" {
        didSet {
            updateObservation()
        }
    }
    var selectedIndex: Int? = nil
    
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
            // ValueObservation will update 'entries' automatically
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
            // ValueObservation will update 'entries' automatically
        }
    }

    func copyEntry(at index: Int) {
        guard index >= 0 && index < entries.count else { return }
        let entry = entries[index]
        Task {
            do {
                let decrypted = try repository.decryptContent(for: entry)
                let pasteService = PasteService()
                try await pasteService.preparePasteboard(for: decrypted)
            } catch {
                print("Failed to copy entry: \(error)")
            }
        }
    }
    
    private var observationTask: Task<Void, Never>?

    init(repository: ClipboardRepository = ClipboardRepository()) {
        self.repository = repository
        setupObservation()
    }

    private func setupObservation() {
        observationTask?.cancel()
        observationTask = Task {
            let stream = repository.observeEntries(limit: 50)
            for await decryptedEntries in stream {
                if !Task.isCancelled {
                    self.entries = decryptedEntries
                }
            }
        }
    }

    private func updateObservation() {
        if searchQuery.isEmpty {
            setupObservation()
        } else {
            observationTask?.cancel()
            observationTask = nil
            do {
                entries = try repository.search(searchQuery)
            } catch {
                print("Search failed: \(error)")
            }
        }
    }
}
