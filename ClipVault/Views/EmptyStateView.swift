//
//  EmptyStateView.swift
//  ClipVault
//

import SwiftUI

/// Animated empty-state illustration shown when there are no clipboard history entries.
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
