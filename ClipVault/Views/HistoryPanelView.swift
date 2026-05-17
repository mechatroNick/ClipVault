//
//  HistoryPanelView.swift
//  ClipVault
//

import SwiftUI

struct HistoryPanelView: View {
    @State var viewModel: ClipboardViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            SearchBarView(text: $viewModel.searchQuery)
                .padding()
            
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
                            isSelected: viewModel.selectedIndex == index
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
