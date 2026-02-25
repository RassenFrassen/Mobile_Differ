import SwiftUI

struct LoadingView: View {
    @State private var progress: Double = 0.0
    
    // Messages green color
    private let messagesGreen = Color(red: 0.0, green: 0.78, blue: 0.36)
    
    var body: some View {
        ZStack {
            // Dark background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // App icon
                if let iconImage = loadAppIcon() {
                    Image(uiImage: iconImage)
                        .resizable()
                        .frame(width: 120, height: 120)
                        .cornerRadius(26.4)
                        .shadow(color: .white.opacity(0.1), radius: 12, x: 0, y: 4)
                } else {
                    // Fallback icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 26.4)
                            .fill(Color(white: 0.15))
                            .frame(width: 120, height: 120)
                            .shadow(color: .white.opacity(0.1), radius: 12, x: 0, y: 4)
                        
                        Image(systemName: "key.horizontal.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(messagesGreen)
                    }
                }
                
                VStack(spacing: 12) {
                    Text("Initializing")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                    
                    Text("Loading Payloads and Keys catalog...")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                // Messages green progress bar
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: messagesGreen))
                    .frame(width: 300)
                    .padding(.top, 8)
            }
        }
        .onAppear {
            // Animate progress
            withAnimation(.easeInOut(duration: 2.0)) {
                progress = 0.7
            }
        }
    }
    
    private func loadAppIcon() -> UIImage? {
        // Try loading from bundle first
        if let image = UIImage(named: "AppIcon120") {
            return image
        }
        
        // Fallback to file path
        if let iconPath = Bundle.main.path(forResource: "AppIcon120", ofType: "png") {
            return UIImage(contentsOfFile: iconPath)
        }
        
        return nil
    }
}

