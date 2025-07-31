import SwiftUI
import CoreMotion

struct RehabilitationView: View {
    @EnvironmentObject var rehabilitationViewModel: RehabilitationViewModel
    @State private var showingExerciseSelection = false
    @State private var showingSessionSummary = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Current Session Status
                    if rehabilitationViewModel.isSessionActive {
                        activeSessionSection
                    } else {
                        exerciseSelectionSection
                    }
                    
                    // Real-time Metrics
                    if rehabilitationViewModel.isSessionActive {
                        realTimeMetricsSection
                    }
                    
                    // ML Prediction
                    if let prediction = rehabilitationViewModel.mlPrediction {
                        mlPredictionSection(prediction)
                    }
                    
                    // Progress Overview
                    progressOverviewSection
                }
                .padding()
            }
            .navigationTitle("PNVR Rehabilitation")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingExerciseSelection) {
                ExerciseSelectionView()
            }
            .sheet(isPresented: $showingSessionSummary) {
                SessionSummaryView()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "figure.walk")
                    .font(.title)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text("Peripheral Neuropathy")
                        .font(.headline)
                    Text("VR Rehabilitation")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if rehabilitationViewModel.isMotionTrackingActive {
                    Image(systemName: "waveform.path.ecg")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }
            
            if let errorMessage = rehabilitationViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Active Session Section
    private var activeSessionSection: some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Active Session")
                        .font(.headline)
                    if let session = rehabilitationViewModel.currentSession {
                        Text(session.exerciseType.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button("End Session") {
                    rehabilitationViewModel.endSession()
                    showingSessionSummary = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            
            if let session = rehabilitationViewModel.currentSession {
                HStack {
                    MetricCard(
                        title: "Duration",
                        value: formatDuration(session.duration),
                        icon: "clock"
                    )
                    
                    MetricCard(
                        title: "Difficulty",
                        value: session.difficulty.rawValue,
                        icon: "star.fill"
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Exercise Selection Section
    private var exerciseSelectionSection: some View {
        VStack(spacing: 15) {
            Text("Start New Session")
                .font(.headline)
            
            Button("Select Exercise") {
                showingExerciseSelection = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Real-time Metrics Section
    private var realTimeMetricsSection: some View {
        VStack(spacing: 15) {
            Text("Real-time Metrics")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                if let balanceMetrics = rehabilitationViewModel.currentBalanceMetrics {
                    MetricCard(
                        title: "Stability Score",
                        value: String(format: "%.1f", balanceMetrics.stabilityScore),
                        icon: "target",
                        color: stabilityColor(balanceMetrics.stabilityScore)
                    )
                    
                    MetricCard(
                        title: "Fall Risk",
                        value: String(format: "%.1f", balanceMetrics.fallRiskIndex),
                        icon: "exclamationmark.triangle",
                        color: riskColor(balanceMetrics.fallRiskIndex)
                    )
                    
                    MetricCard(
                        title: "Sway Area",
                        value: String(format: "%.2f", balanceMetrics.swayArea),
                        icon: "waveform.path"
                    )
                    
                    MetricCard(
                        title: "Sway Velocity",
                        value: String(format: "%.2f", balanceMetrics.swayVelocity),
                        icon: "speedometer"
                    )
                }
                
                if let gaitMetrics = rehabilitationViewModel.currentGaitMetrics {
                    MetricCard(
                        title: "Gait Symmetry",
                        value: String(format: "%.1f%%", gaitMetrics.gaitSymmetry * 100),
                        icon: "figure.walk"
                    )
                    
                    MetricCard(
                        title: "Walking Speed",
                        value: String(format: "%.2f m/s", gaitMetrics.walkingSpeed),
                        icon: "speedometer"
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - ML Prediction Section
    private func mlPredictionSection(_ prediction: MLPrediction) -> some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                Text("ML Recommendation")
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Recommended Exercise:")
                    Spacer()
                    Text(prediction.recommendedExercise.description)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Difficulty Level:")
                    Spacer()
                    Text(prediction.predictedDifficulty.rawValue)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Confidence:")
                    Spacer()
                    Text("\(Int(prediction.confidence * 100))%")
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Risk Assessment:")
                    Spacer()
                    Text(prediction.riskAssessment)
                        .fontWeight(.semibold)
                        .foregroundColor(riskColor(Double(prediction.riskAssessment.contains("High") ? 80 : 30)))
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Progress Overview Section
    private var progressOverviewSection: some View {
        VStack(spacing: 15) {
            Text("Progress Overview")
                .font(.headline)
            
            if let progress = rehabilitationViewModel.progress {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                    MetricCard(
                        title: "Total Sessions",
                        value: "\(progress.totalSessions)",
                        icon: "calendar"
                    )
                    
                    MetricCard(
                        title: "Avg Stability",
                        value: String(format: "%.1f", progress.averageStabilityScore),
                        icon: "target"
                    )
                    
                    MetricCard(
                        title: "Avg Gait Score",
                        value: String(format: "%.1f", progress.averageGaitScore),
                        icon: "figure.walk"
                    )
                    
                    MetricCard(
                        title: "Improvement",
                        value: String(format: "%.1f%%", progress.improvementRate),
                        icon: "arrow.up.right",
                        color: progress.improvementRate > 0 ? .green : .red
                    )
                }
            } else {
                Text("No progress data available")
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Helper Functions
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func stabilityColor(_ score: Double) -> Color {
        if score >= 80 { return .green }
        else if score >= 60 { return .yellow }
        else { return .red }
    }
    
    private func riskColor(_ risk: Double) -> Color {
        if risk <= 30 { return .green }
        else if risk <= 60 { return .yellow }
        else { return .red }
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = .blue
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    RehabilitationView()
        .environmentObject(RehabilitationViewModel())
} 