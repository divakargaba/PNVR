import SwiftUI
import Charts

struct SessionSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var rehabilitationViewModel: RehabilitationViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Session Overview
                    sessionOverviewSection
                    
                    // Performance Metrics
                    performanceMetricsSection
                    
                    // Progress Chart
                    if #available(iOS 16.0, *) {
                        progressChartSection
                    }
                    
                    // Recommendations
                    recommendationsSection
                    
                    // Next Steps
                    nextStepsSection
                }
                .padding()
            }
            .navigationTitle("Session Summary")
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
    
    // MARK: - Session Overview Section
    private var sessionOverviewSection: some View {
        VStack(spacing: 15) {
            Text("Session Overview")
                .font(.headline)
            
            if let session = rehabilitationViewModel.currentSession {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                    SummaryCard(
                        title: "Exercise Type",
                        value: session.exerciseType.description,
                        icon: session.exerciseType.icon,
                        color: .blue
                    )
                    
                    SummaryCard(
                        title: "Difficulty",
                        value: session.difficulty.rawValue,
                        icon: "star.fill",
                        color: .orange
                    )
                    
                    SummaryCard(
                        title: "Duration",
                        value: formatDuration(session.duration),
                        icon: "clock",
                        color: .green
                    )
                    
                    SummaryCard(
                        title: "Overall Score",
                        value: String(format: "%.1f", session.overallScore),
                        icon: "target",
                        color: scoreColor(session.overallScore)
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Performance Metrics Section
    private var performanceMetricsSection: some View {
        VStack(spacing: 15) {
            Text("Performance Metrics")
                .font(.headline)
            
            if let session = rehabilitationViewModel.currentSession {
                VStack(spacing: 12) {
                    // Balance Performance
                    if !session.balanceMetrics.isEmpty {
                        let avgStability = session.balanceMetrics.map { $0.stabilityScore }.reduce(0, +) / Double(session.balanceMetrics.count)
                        let avgFallRisk = session.balanceMetrics.map { $0.fallRiskIndex }.reduce(0, +) / Double(session.balanceMetrics.count)
                        
                        MetricRow(
                            title: "Average Stability Score",
                            value: String(format: "%.1f", avgStability),
                            color: stabilityColor(avgStability)
                        )
                        
                        MetricRow(
                            title: "Average Fall Risk",
                            value: String(format: "%.1f", avgFallRisk),
                            color: riskColor(avgFallRisk)
                        )
                    }
                    
                    // Gait Performance
                    if !session.gaitMetrics.isEmpty {
                        let avgSymmetry = session.gaitMetrics.map { $0.gaitSymmetry }.reduce(0, +) / Double(session.gaitMetrics.count)
                        let avgSpeed = session.gaitMetrics.map { $0.walkingSpeed }.reduce(0, +) / Double(session.gaitMetrics.count)
                        
                        MetricRow(
                            title: "Average Gait Symmetry",
                            value: String(format: "%.1f%%", avgSymmetry * 100),
                            color: symmetryColor(avgSymmetry)
                        )
                        
                        MetricRow(
                            title: "Average Walking Speed",
                            value: String(format: "%.2f m/s", avgSpeed),
                            color: .blue
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Progress Chart Section
    @available(iOS 16.0, *)
    private var progressChartSection: some View {
        VStack(spacing: 15) {
            Text("Session Progress")
                .font(.headline)
            
            if let session = rehabilitationViewModel.currentSession {
                Chart {
                    ForEach(Array(session.balanceMetrics.enumerated()), id: \.offset) { index, metric in
                        LineMark(
                            x: .value("Time", index),
                            y: .value("Stability", metric.stabilityScore)
                        )
                        .foregroundStyle(.green)
                        
                        LineMark(
                            x: .value("Time", index),
                            y: .value("Fall Risk", metric.fallRiskIndex)
                        )
                        .foregroundStyle(.red)
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartLegend(position: .bottom)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Recommendations Section
    private var recommendationsSection: some View {
        VStack(spacing: 15) {
            Text("Recommendations")
                .font(.headline)
            
            if let prediction = rehabilitationViewModel.mlPrediction {
                VStack(alignment: .leading, spacing: 12) {
                    RecommendationRow(
                        title: "Next Exercise",
                        value: prediction.recommendedExercise.description,
                        icon: prediction.recommendedExercise.icon
                    )
                    
                    RecommendationRow(
                        title: "Suggested Difficulty",
                        value: prediction.predictedDifficulty.rawValue,
                        icon: "star.fill"
                    )
                    
                    RecommendationRow(
                        title: "Risk Assessment",
                        value: prediction.riskAssessment,
                        icon: "exclamationmark.triangle"
                    )
                    
                    RecommendationRow(
                        title: "ML Confidence",
                        value: "\(Int(prediction.confidence * 100))%",
                        icon: "brain.head.profile"
                    )
                }
            } else {
                Text("No recommendations available")
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Next Steps Section
    private var nextStepsSection: some View {
        VStack(spacing: 15) {
            Text("Next Steps")
                .font(.headline)
            
            VStack(spacing: 12) {
                NextStepCard(
                    title: "Continue Training",
                    description: "Practice regularly to maintain and improve your balance and gait",
                    icon: "arrow.right.circle.fill",
                    color: .green
                )
                
                NextStepCard(
                    title: "Monitor Progress",
                    description: "Track your improvements over time in the Metrics tab",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                )
                
                NextStepCard(
                    title: "Consult Healthcare Provider",
                    description: "Share your progress with your healthcare team",
                    icon: "heart.fill",
                    color: .red
                )
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
    
    private func scoreColor(_ score: Double) -> Color {
        if score >= 80 { return .green }
        else if score >= 60 { return .yellow }
        else { return .red }
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
    
    private func symmetryColor(_ symmetry: Double) -> Color {
        if symmetry >= 0.9 { return .green }
        else if symmetry >= 0.7 { return .yellow }
        else { return .red }
    }
}

// MARK: - Summary Card
struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
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

// MARK: - Metric Row
struct MetricRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Recommendation Row
struct RecommendationRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            Spacer()
        }
    }
}

// MARK: - Next Step Card
struct NextStepCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    SessionSummaryView()
        .environmentObject(RehabilitationViewModel())
} 