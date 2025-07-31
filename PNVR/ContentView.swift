import SwiftUI

struct ContentView: View {
    @EnvironmentObject var rehabilitationViewModel: RehabilitationViewModel
    @EnvironmentObject var healthKitService: HealthKitService
    
    var body: some View {
        TabView {
            RehabilitationView()
                .tabItem {
                    Image(systemName: "figure.walk")
                    Text("Rehabilitation")
                }
            
            MetricsView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Metrics")
                }
            
            VRIntegrationView()
                .tabItem {
                    Image(systemName: "visionpro")
                    Text("VR Integration")
                }
        }
        .accentColor(.blue)
        .onAppear {
            // Initialize services when app loads
            rehabilitationViewModel.startMotionTracking()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(RehabilitationViewModel())
        .environmentObject(HealthKitService())
} 