import SwiftUI

struct Theme {
    static let brandPrimary = Color.blue
    static let brandSecondary = Color.purple
    static let brandGradient = LinearGradient(
        gradient: Gradient(colors: [brandPrimary, brandSecondary]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Semantic colors
    static let success = Color.green
    static let warning = Color.orange
    static let danger = Color.red
    static let textSecondary = Color.secondary
}
