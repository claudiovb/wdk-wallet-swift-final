import SwiftUI

struct ContentView: View {
    @State private var status: String = "Initializing..."
    @State private var isLoading: Bool = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Logo/Icon
                Image(systemName: "bitcoinsign.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                    .padding(.top, 40)
                
                // Title
                Text("WDK Wallet Demo")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Status section
                VStack(spacing: 15) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.green)
                    }
                    
                    Text(status)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
                
                // Information section
                VStack(alignment: .leading, spacing: 15) {
                    InfoRow(icon: "network", title: "Multi-Chain", description: "Ethereum, Solana, Polygon")
                    InfoRow(icon: "lock.shield", title: "Secure", description: "AES-256-GCM encryption")
                    InfoRow(icon: "bolt.fill", title: "Fast", description: "JSON-RPC 2.0 protocol")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
                
                Spacer()
                
                // Footer
                Text("Check the console for detailed logs")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
            .onAppear {
                // Simulate initialization
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        status = "WDK initialized successfully!\nCheck console for details."
                        isLoading = false
                    }
                }
            }
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    ContentView()
}
