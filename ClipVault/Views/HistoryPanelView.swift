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
    /// Called when the quit button is tapped.
    var onQuit: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header bar with gear (left) and close/quit (right)
            HStack(spacing: 16) {
                Button(action: {
                    onOpenSettings?()
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18))
                        .padding(10)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")
                
                Spacer()
                
                Button(action: {
                    onClose?()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .padding(10)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
                
                Button(action: {
                    onQuit?()
                }) {
                    Image(systemName: "power")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.red)
                        .padding(10)
                        .background(Color.red.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Quit")
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            SearchBarView(text: $viewModel.searchQuery, isFocused: $viewModel.isSearchFocused)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            
            Divider()
            
            if viewModel.entries.isEmpty && !viewModel.isLoading {
                EmptyStateView()
            } else {
                List {
                    ForEach(Array(viewModel.entries.enumerated()), id: \.element.id) { index, entry in
                        EntryRowView(
                            entry: entry,
                            isSelected: viewModel.selectedIndex == index,
                            isActive: entry.contentHash == viewModel.activeHash,
                            repository: viewModel.repository,
                            onTogglePin: { viewModel.togglePin(at: index) },
                            onDelete: { 
                                withAnimation(.spring()) {
                                    viewModel.deleteEntry(at: index)
                                }
                            },
                            onCopy: { viewModel.copyEntry(at: index) },
                            onSelect: { viewModel.selectedIndex = index }
                        )
                        .onTapGesture {
                            viewModel.selectedIndex = index
                        }
                        .onAppear {
                            if index == viewModel.entries.count - 1 {
                                viewModel.loadMoreEntries()
                            }
                        }
                        .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                    }

                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .scaleEffect(0.5)
                            Spacer()
                        }
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .animation(.spring(), value: viewModel.entries)
            }
        }
        .onAppear {
            viewModel.refreshActiveHash()
        }
        .frame(minWidth: 300, minHeight: 400)
        .background(VisualEffectView(material: .menu, blendingMode: .behindWindow))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
import SwiftUI

struct EmptyStateView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)
                
                Image(systemName: "clipboard")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor.opacity(0.8))
                    .offset(y: isAnimating ? -5 : 5)
            }
            .animation(
                ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil 
                ? nil 
                : .easeInOut(duration: 2.0).repeatForever(autoreverses: true), 
                value: isAnimating
            )
            
            VStack(spacing: 8) {
                Text("Your Vault is Empty")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("Copy anything (⌘C) to see it here.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            isAnimating = true
        }
    }
}
