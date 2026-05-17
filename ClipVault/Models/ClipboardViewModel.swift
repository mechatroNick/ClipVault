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
    
    private var observation: Any?

    init(repository: ClipboardRepository = ClipboardRepository()) {
        self.repository = repository
        setupObservation()
    }

    private func setupObservation() {
        // Observe changes in the database and update 'entries' automatically.
        let observation = ValueObservation.tracking { db in
            try ClipboardEntry
                .order(ClipboardEntry.Columns.timestamp.desc)
                .limit(50)
                .fetchAll(db)
        }

        self.observation = observation.start(
            in: repository.dbManager.dbQueue,
            onError: { error in print("Observation error: \(error)") },
            onChange: { [weak self] entries in
                Task { @MainActor in
                    self?.entries = entries
                }
            }
        )
    }

    private func updateObservation() {
        // If searchQuery changes, we might want to restart observation with a filter.
        // For MVP simplicity, we can just fetch once for search, or restart observation.
        if searchQuery.isEmpty {
            setupObservation()
        } else {
            // Cancel current observation and fetch search results
            observation = nil
            do {
                entries = try repository.search(searchQuery)
            } catch {
                print("Search failed: \(error)")
            }
        }
    }
}
