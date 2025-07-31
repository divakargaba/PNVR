import SwiftUI
import ARKit
import RealityKit

struct VRIntegrationView: View {
    @EnvironmentObject var rehabilitationViewModel: RehabilitationViewModel
    @State private var isVRActive = false
    @State private var showingVRSetup = false
    @State private var vrConnectionStatus: VRConnectionStatus = .disconnected
    
    enum VRConnectionStatus {
        case disconnected
        case connecting
        case connected
        case error
        
        var description: String {
            switch self {
            case .disconnected: return "Disconnected"
            case .connecting: return "Connecting..."
            case .connected: return "Connected"
            case .error: return "Connection Error"
            }
        }
        
        var color: Color {
            switch self {
            case .disconnected: return .red
            case .connecting: return .yellow
            case .connected: return .green
            case .error: return .red
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // VR Status Header
                    vrStatusHeader
                    
                    // VR Tracking Data
                    if isVRActive {
                        vrTrackingSection
                    }
                    
                    // VR Controls
                    vrControlsSection
                    
                    // VR Feedback
                    if isVRActive {
                        vrFeedbackSection
                    }
                    
                    // VR Settings
                    vrSettingsSection
                }
                .padding()
            }
            .navigationTitle("VR Integration")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingVRSetup) {
                VRSetupView()
            }
        }
    }
    
    // MARK: - VR Status Header
    private var vrStatusHeader: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "visionpro")
                    .font(.title)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text("VR Headset Status")
                        .font(.headline)
                    Text(vrConnectionStatus.description)
                        .font(.subheadline)
                        .foregroundColor(vrConnectionStatus.color)
                }
                
                Spacer()
                
                Circle()
                    .fill(vrConnectionStatus.color)
                    .frame(width: 12, height: 12)
            }
            
            if isVRActive {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Tracking Active")
                            .font(.subheadline)
                            .foregroundColor(.green)
                        Text("Foot & Torso sensors online")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "waveform.path.ecg")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - VR Tracking Section
    private var vrTrackingSection: some View {
        VStack(spacing: 15) {
            Text("Real-time VR Tracking")
                .font(.headline)
            
            if let vrData = rehabilitationViewModel.currentVRTrackingData {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                    VRTrackingCard(
                        title: "Foot Position",
                        xValue: String(format: "%.1f", vrData.footPosition.x),
                        yValue: String(format: "%.1f", vrData.footPosition.y),
                        icon: "figure.walk"
                    )
                    
                    VRTrackingCard(
                        title: "Torso Position",
                        xValue: String(format: "%.1f", vrData.torsoPosition.x),
                        yValue: String(format: "%.1f", vrData.torsoPosition.y),
                        icon: "person.fill"
                    )
                    
                    VRTrackingCard(
                        title: "Foot Velocity",
                        xValue: String(format: "%.2f", vrData.footVelocity.dx),
                        yValue: String(format: "%.2f", vrData.footVelocity.dy),
                        icon: "speedometer"
                    )
                    
                    VRTrackingCard(
                        title: "Balance Offset",
                        xValue: String(format: "%.2f", vrData.balanceOffset),
                        yValue: "",
                        icon: "target"
                    )
                }
            } else {
                Text("No VR tracking data available")
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - VR Controls Section
    private var vrControlsSection: some View {
        VStack(spacing: 15) {
            Text("VR Controls")
                .font(.headline)
            
            HStack(spacing: 15) {
                Button(action: {
                    if isVRActive {
                        stopVR()
                    } else {
                        startVR()
                    }
                }) {
                    HStack {
                        Image(systemName: isVRActive ? "stop.circle.fill" : "play.circle.fill")
                        Text(isVRActive ? "Stop VR" : "Start VR")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isVRActive ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Button("Setup") {
                    showingVRSetup = true
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            if vrConnectionStatus == .error {
                Button("Retry Connection") {
                    retryVRConnection()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - VR Feedback Section
    private var vrFeedbackSection: some View {
        VStack(spacing: 15) {
            Text("VR Feedback")
                .font(.headline)
            
            if let vrData = rehabilitationViewModel.currentVRTrackingData {
                VStack(spacing: 10) {
                    HStack {
                        Text("Balance Status:")
                        Spacer()
                        Text(balanceStatusText(vrData.balanceOffset))
                            .fontWeight(.semibold)
                            .foregroundColor(balanceStatusColor(vrData.balanceOffset))
                    }
                    
                    HStack {
                        Text("Movement Quality:")
                        Spacer()
                        Text(movementQualityText(vrData))
                            .fontWeight(.semibold)
                            .foregroundColor(movementQualityColor(vrData))
                    }
                    
                    HStack {
                        Text("VR Guidance:")
                        Spacer()
                        Text(vrGuidanceText(vrData))
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - VR Settings Section
    private var vrSettingsSection: some View {
        VStack(spacing: 15) {
            Text("VR Settings")
                .font(.headline)
            
            VStack(spacing: 10) {
                HStack {
                    Text("Tracking Sensitivity:")
                    Spacer()
                    Text("High")
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Haptic Feedback:")
                    Spacer()
                    Text("Enabled")
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("Visual Cues:")
                    Spacer()
                    Text("Enabled")
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("Audio Feedback:")
                    Spacer()
                    Text("Enabled")
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - VR Control Functions
    private func startVR() {
        vrConnectionStatus = .connecting
        
        // Simulate VR connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.vrConnectionStatus = .connected
            self.isVRActive = true
        }
    }
    
    private func stopVR() {
        isVRActive = false
        vrConnectionStatus = .disconnected
    }
    
    private func retryVRConnection() {
        vrConnectionStatus = .connecting
        
        // Simulate retry
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.vrConnectionStatus = .connected
            self.isVRActive = true
        }
    }
    
    // MARK: - Helper Functions
    private func balanceStatusText(_ offset: Double) -> String {
        if offset < 0.1 { return "Excellent" }
        else if offset < 0.3 { return "Good" }
        else if offset < 0.5 { return "Fair" }
        else { return "Poor" }
    }
    
    private func balanceStatusColor(_ offset: Double) -> Color {
        if offset < 0.1 { return .green }
        else if offset < 0.3 { return .yellow }
        else if offset < 0.5 { return .orange }
        else { return .red }
    }
    
    private func movementQualityText(_ vrData: VRTrackingData) -> String {
        let footVelocity = sqrt(pow(vrData.footVelocity.dx, 2) + pow(vrData.footVelocity.dy, 2))
        let torsoVelocity = sqrt(pow(vrData.torsoVelocity.dx, 2) + pow(vrData.torsoVelocity.dy, 2))
        
        let totalVelocity = footVelocity + torsoVelocity
        
        if totalVelocity < 0.5 { return "Smooth" }
        else if totalVelocity < 1.0 { return "Moderate" }
        else { return "Jerky" }
    }
    
    private func movementQualityColor(_ vrData: VRTrackingData) -> Color {
        let footVelocity = sqrt(pow(vrData.footVelocity.dx, 2) + pow(vrData.footVelocity.dy, 2))
        let torsoVelocity = sqrt(pow(vrData.torsoVelocity.dx, 2) + pow(vrData.torsoVelocity.dy, 2))
        
        let totalVelocity = footVelocity + torsoVelocity
        
        if totalVelocity < 0.5 { return .green }
        else if totalVelocity < 1.0 { return .yellow }
        else { return .red }
    }
    
    private func vrGuidanceText(_ vrData: VRTrackingData) -> String {
        if vrData.balanceOffset > 0.5 {
            return "Focus on balance"
        } else if vrData.footVelocity.dx > 0.3 {
            return "Slow down movement"
        } else {
            return "Maintain current pace"
        }
    }
}

// MARK: - VR Tracking Card
struct VRTrackingCard: View {
    let title: String
    let xValue: String
    let yValue: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 4) {
                if !yValue.isEmpty {
                    Text("X: \(xValue)")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("Y: \(yValue)")
                        .font(.caption)
                        .fontWeight(.semibold)
                } else {
                    Text(xValue)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - VR Setup View
struct VRSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedHeadset = "Meta Quest 3"
    @State private var selectedControllers = "Hand Controllers"
    @State private var isCalibrating = false
    
    let availableHeadsets = ["Meta Quest 3", "HTC Vive", "Valve Index", "Oculus Rift"]
    let availableControllers = ["Hand Controllers", "Foot Sensors", "Torso Tracker", "Full Body Tracking"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("VR Headset") {
                    Picker("Headset", selection: $selectedHeadset) {
                        ForEach(availableHeadsets, id: \.self) { headset in
                            Text(headset).tag(headset)
                        }
                    }
                }
                
                Section("Tracking Devices") {
                    Picker("Controllers", selection: $selectedControllers) {
                        ForEach(availableControllers, id: \.self) { controller in
                            Text(controller).tag(controller)
                        }
                    }
                }
                
                Section("Calibration") {
                    Button(isCalibrating ? "Calibrating..." : "Start Calibration") {
                        startCalibration()
                    }
                    .disabled(isCalibrating)
                }
                
                Section("Connection Status") {
                    HStack {
                        Text("Headset")
                        Spacer()
                        Text("Connected")
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Text("Foot Sensors")
                        Spacer()
                        Text("Connected")
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Text("Torso Tracker")
                        Spacer()
                        Text("Connected")
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("VR Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func startCalibration() {
        isCalibrating = true
        
        // Simulate calibration process
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isCalibrating = false
        }
    }
}

#Preview {
    VRIntegrationView()
        .environmentObject(RehabilitationViewModel())
} 