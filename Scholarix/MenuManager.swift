import SwiftUI
import Combine

class MenuManager: ObservableObject {
    @Published var isOpen: Bool
    // --- NEW: Track settings state here ---
    @Published var showSettings: Bool
    
    init() {
        self.isOpen = false
        self.showSettings = false
    }
    
    func open() {
        withAnimation(.spring()) { isOpen = true }
    }
    
    func close() {
        withAnimation(.spring()) { isOpen = false }
    }
    
    func toggle() {
        withAnimation(.spring()) { isOpen.toggle() }
    }
    
    // --- NEW: Helper to transition from Menu to Settings ---
    func openSettings() {
        // Close the side menu first/simultaneously
        withAnimation(.easeInOut(duration: 0.3)) {
            isOpen = false
            showSettings = true
        }
    }
    
    func closeSettings() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showSettings = false
        }
    }
}
