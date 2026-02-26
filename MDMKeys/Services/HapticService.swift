import UIKit
import SwiftUI

/// Provides haptic feedback throughout the app for enhanced user experience
enum HapticService {
    
    /// Light impact feedback for selections
    static func selectionChanged() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    /// Light impact feedback for UI interactions
    static func lightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Medium impact feedback for important actions
    static func mediumImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Heavy impact feedback for significant actions
    static func heavyImpact() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /// Success feedback for completed actions
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Warning feedback for caution scenarios
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// Error feedback for failures
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}

/// SwiftUI View extension for easy haptic feedback
extension View {
    /// Adds haptic feedback when the view is tapped
    func hapticFeedback(_ style: HapticFeedbackStyle = .light) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                switch style {
                case .selection:
                    HapticService.selectionChanged()
                case .light:
                    HapticService.lightImpact()
                case .medium:
                    HapticService.mediumImpact()
                case .heavy:
                    HapticService.heavyImpact()
                case .success:
                    HapticService.success()
                case .warning:
                    HapticService.warning()
                case .error:
                    HapticService.error()
                }
            }
        )
    }
}

enum HapticFeedbackStyle {
    case selection
    case light
    case medium
    case heavy
    case success
    case warning
    case error
}
