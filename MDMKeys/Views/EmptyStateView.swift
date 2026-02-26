import SwiftUI

/// Reusable empty state view for lists and search results
struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImage)
                .font(.system(size: 64))
                .foregroundStyle(.secondary.opacity(0.5))
                .symbolEffect(.pulse)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Label(actionTitle, systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}

/// Empty state specifically for search with no results
struct SearchEmptyStateView: View {
    let searchText: String
    
    var body: some View {
        EmptyStateView(
            systemImage: "magnifyingglass",
            title: "No Results Found",
            message: "No MDM keys match '\(searchText)'. Try adjusting your search or filters."
        )
    }
}

/// Empty state for when catalog is empty (shouldn't happen, but good fallback)
struct CatalogEmptyStateView: View {
    let onRefresh: () -> Void
    
    var body: some View {
        EmptyStateView(
            systemImage: "tray.fill",
            title: "No Data Available",
            message: "The MDM catalog is empty. Try refreshing to load the latest data.",
            actionTitle: "Refresh Catalog",
            action: onRefresh
        )
    }
}

/// Empty state for notification log
struct NotificationEmptyStateView: View {
    var body: some View {
        EmptyStateView(
            systemImage: "bell.slash.fill",
            title: "No Updates Yet",
            message: "When you refresh the catalog and changes are detected, they'll appear here."
        )
    }
}

/// Empty state for when network is unavailable
struct NetworkErrorStateView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        EmptyStateView(
            systemImage: "wifi.exclamationmark",
            title: "Connection Issue",
            message: message,
            actionTitle: "Try Again",
            action: onRetry
        )
    }
}

/// Loading skeleton for lists
struct ListLoadingSkeleton: View {
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<8, id: \.self) { _ in
                SkeletonRow()
            }
        }
    }
}

struct SkeletonRow: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 4)
                .fill(.gray.opacity(0.2))
                .frame(width: 200, height: 16)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(.gray.opacity(0.15))
                .frame(width: 280, height: 14)
            
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.gray.opacity(0.1))
                    .frame(width: 60, height: 20)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(.gray.opacity(0.1))
                    .frame(width: 60, height: 20)
            }
        }
        .padding()
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear {
            isAnimating = true
        }
    }
}
