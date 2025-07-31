import SwiftUI
import Charts

struct MetricsView: View {
    @EnvironmentObject var rehabilitationViewModel: RehabilitationViewModel
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedMetric: MetricType = .stabilityScore
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case threeMonths = "3 Months"
        case year = "Year"
    }
    
    enum MetricType: String, CaseIterable {
        case stabilityScore = "Stability Score"
        case fallRiskIndex = "Fall Risk"
        case gaitSymmetry = "Gait Symmetry"
        case walkingSpeed = "Walking Speed"
        case swayArea = "Sway Area"
        case cadence = "Cadence"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Time Range Selector
                    timeRangeSelector
                    
                    // Metric Type Selector
                    metricTypeSelector
                    
                    // Chart View
                    chartSection
                    
                    // Summary Statistics
                    summaryStatisticsSection
                    
                    // Session History
                    sessionHistorySection
                    
                    // Fall Risk Analysis
                    fallRiskAnalysisSection
                }
                .padding()
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Time Range Selector
    private var timeRangeSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Time Range")
                .font(.headline)
            
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Metric Type Selector
    private var metricTypeSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Metric Type")
                .font(.headline)
            
            Picker("Metric Type", selection: $selectedMetric) {
                ForEach(MetricType.allCases, id: \.self) { metric in
                    Text(metric.rawValue).tag(metric)
                }
            }
            .pickerStyle(.menu)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Chart Section
    private var chartSection: some View {
        VStack(spacing: 15) {
            Text("\(selectedMetric.rawValue) Over Time")
                .font(.headline)
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(filteredData, id: \.timestamp) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.timestamp),
                            y: .value("Value", dataPoint.value)
                        )
                        .foregroundStyle(chartColor)
                        
                        AreaMark(
                            x: .value("Date", dataPoint.timestamp),
                            y: .value("Value", dataPoint.value)
                        )
                        .foregroundStyle(chartColor.opacity(0.1))
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.day())
                    }
                }
            } else {
                // Fallback for iOS 15
                Text("Charts require iOS 16+")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Summary Statistics Section
    private var summaryStatisticsSection: some View {
        VStack(spacing: 15) {
            Text("Summary Statistics")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                StatisticCard(
                    title: "Average",
                    value: String(format: "%.2f", averageValue),
                    icon: "chart.bar.fill"
                )
                
                StatisticCard(
                    title: "Best",
                    value: String(format: "%.2f", bestValue),
                    icon: "arrow.up.circle.fill",
                    color: .green
                )
                
                StatisticCard(
                    title: "Worst",
                    value: String(format: "%.2f", worstValue),
                    icon: "arrow.down.circle.fill",
                    color: .red
                )
                
                StatisticCard(
                    title: "Trend",
                    value: trendValue,
                    icon: trendIcon,
                    color: trendColor
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Session History Section
    private var sessionHistorySection: some View {
        VStack(spacing: 15) {
            Text("Recent Sessions")
                .font(.headline)
            
            ForEach(recentSessions) { session in
                SessionHistoryRow(session: session)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Fall Risk Analysis Section
    private var fallRiskAnalysisSection: some View {
        VStack(spacing: 15) {
            Text("Fall Risk Analysis")
                .font(.headline)
            
            if let progress = rehabilitationViewModel.progress {
                VStack(spacing: 10) {
                    HStack {
                        Text("Current Risk Level:")
                        Spacer()
                        Text(riskLevelText(progress.fallRiskTrend.last ?? 0))
                            .fontWeight(.semibold)
                            .foregroundColor(riskColor(progress.fallRiskTrend.last ?? 0))
                    }
                    
                    HStack {
                        Text("Risk Trend:")
                        Spacer()
                        Text(riskTrendText(progress.fallRiskTrend))
                            .fontWeight(.semibold)
                            .foregroundColor(riskTrendColor(progress.fallRiskTrend))
                    }
                    
                    HStack {
                        Text("Recommendation:")
                        Spacer()
                        Text(recommendationText(progress.fallRiskTrend.last ?? 0))
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
                .font(.subheadline)
            } else {
                Text("No fall risk data available")
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Computed Properties
    private var filteredData: [DataPoint] {
        let sessions = rehabilitationViewModel.sessionHistory
        let cutoffDate = Calendar.current.date(byAdding: timeRangeComponent, value: -timeRangeValue, to: Date()) ?? Date()
        
        let filteredSessions = sessions.filter { $0.startTime >= cutoffDate }
        
        return filteredSessions.flatMap { session in
            switch selectedMetric {
            case .stabilityScore:
                return session.balanceMetrics.map { DataPoint(timestamp: $0.timestamp, value: $0.stabilityScore) }
            case .fallRiskIndex:
                return session.balanceMetrics.map { DataPoint(timestamp: $0.timestamp, value: $0.fallRiskIndex) }
            case .gaitSymmetry:
                return session.gaitMetrics.map { DataPoint(timestamp: $0.timestamp, value: $0.gaitSymmetry * 100) }
            case .walkingSpeed:
                return session.gaitMetrics.map { DataPoint(timestamp: $0.timestamp, value: $0.walkingSpeed) }
            case .swayArea:
                return session.balanceMetrics.map { DataPoint(timestamp: $0.timestamp, value: $0.swayArea) }
            case .cadence:
                return session.gaitMetrics.map { DataPoint(timestamp: $0.timestamp, value: $0.cadence) }
            }
        }.sorted { $0.timestamp < $1.timestamp }
    }
    
    private var timeRangeComponent: Calendar.Component {
        switch selectedTimeRange {
        case .week: return .weekOfYear
        case .month: return .month
        case .threeMonths: return .month
        case .year: return .year
        }
    }
    
    private var timeRangeValue: Int {
        switch selectedTimeRange {
        case .week: return 1
        case .month: return 1
        case .threeMonths: return 3
        case .year: return 1
        }
    }
    
    private var chartColor: Color {
        switch selectedMetric {
        case .stabilityScore: return .green
        case .fallRiskIndex: return .red
        case .gaitSymmetry: return .blue
        case .walkingSpeed: return .orange
        case .swayArea: return .purple
        case .cadence: return .teal
        }
    }
    
    private var averageValue: Double {
        let values = filteredData.map { $0.value }
        return values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
    }
    
    private var bestValue: Double {
        let values = filteredData.map { $0.value }
        return values.max() ?? 0
    }
    
    private var worstValue: Double {
        let values = filteredData.map { $0.value }
        return values.min() ?? 0
    }
    
    private var trendValue: String {
        guard filteredData.count >= 2 else { return "N/A" }
        
        let recentValues = Array(filteredData.suffix(5)).map { $0.value }
        let olderValues = Array(filteredData.prefix(5)).map { $0.value }
        
        let recentAvg = recentValues.reduce(0, +) / Double(recentValues.count)
        let olderAvg = olderValues.reduce(0, +) / Double(olderValues.count)
        
        let change = ((recentAvg - olderAvg) / olderAvg) * 100
        
        return String(format: "%.1f%%", change)
    }
    
    private var trendIcon: String {
        guard filteredData.count >= 2 else { return "minus.circle" }
        
        let recentValues = Array(filteredData.suffix(5)).map { $0.value }
        let olderValues = Array(filteredData.prefix(5)).map { $0.value }
        
        let recentAvg = recentValues.reduce(0, +) / Double(recentValues.count)
        let olderAvg = olderValues.reduce(0, +) / Double(olderValues.count)
        
        return recentAvg > olderAvg ? "arrow.up.circle" : "arrow.down.circle"
    }
    
    private var trendColor: Color {
        guard filteredData.count >= 2 else { return .gray }
        
        let recentValues = Array(filteredData.suffix(5)).map { $0.value }
        let olderValues = Array(filteredData.prefix(5)).map { $0.value }
        
        let recentAvg = recentValues.reduce(0, +) / Double(recentValues.count)
        let olderAvg = olderValues.reduce(0, +) / Double(olderValues.count)
        
        return recentAvg > olderAvg ? .green : .red
    }
    
    private var recentSessions: [ExerciseSession] {
        return Array(rehabilitationViewModel.sessionHistory.suffix(5)).reversed()
    }
    
    // MARK: - Helper Functions
    private func riskLevelText(_ risk: Double) -> String {
        if risk <= 30 { return "Low" }
        else if risk <= 60 { return "Medium" }
        else { return "High" }
    }
    
    private func riskColor(_ risk: Double) -> Color {
        if risk <= 30 { return .green }
        else if risk <= 60 { return .yellow }
        else { return .red }
    }
    
    private func riskTrendText(_ trend: [Double]) -> String {
        guard trend.count >= 2 else { return "Insufficient Data" }
        
        let recent = trend.suffix(3).reduce(0, +) / Double(trend.suffix(3).count)
        let older = trend.prefix(3).reduce(0, +) / Double(trend.prefix(3).count)
        
        if recent < older { return "Improving" }
        else if recent > older { return "Worsening" }
        else { return "Stable" }
    }
    
    private func riskTrendColor(_ trend: [Double]) -> Color {
        guard trend.count >= 2 else { return .gray }
        
        let recent = trend.suffix(3).reduce(0, +) / Double(trend.suffix(3).count)
        let older = trend.prefix(3).reduce(0, +) / Double(trend.prefix(3).count)
        
        if recent < older { return .green }
        else if recent > older { return .red }
        else { return .yellow }
    }
    
    private func recommendationText(_ risk: Double) -> String {
        if risk <= 30 { return "Continue current routine" }
        else if risk <= 60 { return "Increase balance exercises" }
        else { return "Consult healthcare provider" }
    }
}

// MARK: - Data Point
struct DataPoint {
    let timestamp: Date
    let value: Double
}

// MARK: - Statistic Card
struct StatisticCard: View {
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
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Session History Row
struct SessionHistoryRow: View {
    let session: ExerciseSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.exerciseType.description)
                    .font(.headline)
                
                Text(session.startTime, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1f", session.overallScore))
                    .font(.headline)
                    .foregroundColor(scoreColor(session.overallScore))
                
                Text(session.difficulty.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func scoreColor(_ score: Double) -> Color {
        if score >= 80 { return .green }
        else if score >= 60 { return .yellow }
        else { return .red }
    }
}

#Preview {
    MetricsView()
        .environmentObject(RehabilitationViewModel())
} 