import SwiftUI
import CoreMotion
import HealthKit

@main
struct PNVRApp: App {
    @StateObject private var rehabilitationViewModel = RehabilitationViewModel()
    @StateObject private var healthKitService = HealthKitService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(rehabilitationViewModel)
                .environmentObject(healthKitService)
                .onAppear {
                    // Request HealthKit permissions on app launch
                    healthKitService.requestAuthorization()
                }
        }
    }
} 