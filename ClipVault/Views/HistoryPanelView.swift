//
//  HistoryPanelView.swift
//  ClipVault
//

import SwiftUI

struct HistoryPanelView: View {
    @State var viewModel: ClipboardViewModel
    
    /// Called when the close (X) button is tapped.
    var onClose: (() -> Void)? = nil
    /// Called when the gear (settings) button is tapped.
    var onOpenSettings: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header bar with gear (left) and close (right)
            HStack {
                Button(action: {
                    onOpenSettings?()
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")
                
                Spacer()
                
                Button(action: {
                    onClose?()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 4)
            
            SearchBarView(text: $viewModel.searchQuery)
                .padding(.horizontal)
                .padding(.bottom, 8)
            
            Divider()
            
            if viewModel.entries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clipboard")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No history yet")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(Array(viewModel.entries.enumerated()), id: \.element.id) { index, entry in
                        EntryRowView(
                            entry: entry,
                            isSelected: viewModel.selectedIndex == index,
                            onTogglePin: { viewModel.togglePin(at: index) },
                            onDelete: { viewModel.deleteEntry(at: index) }
                        )
                        .onTapGesture {
                            viewModel.selectedIndex = index
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(width: 350, height: 500)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
