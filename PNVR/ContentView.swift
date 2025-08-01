import SwiftUI
import CoreMotion
import Foundation

// MARK: - Main App
@main
struct PNVRApp: App {
    @StateObject private var rehabilitationViewModel = RehabilitationViewModel()
    @StateObject private var healthKitService = HealthKitService()
    
    var body: some Scene {
        WindowGroup {
            MainContentView()
                .environmentObject(rehabilitationViewModel)
                .environmentObject(healthKitService)
                .onAppear {
                    // Try HealthKit authorization but don't crash if it fails
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        healthKitService.requestAuthorization()
                    }
                }
        }
    }
}

// MARK: - Main Content View
struct MainContentView: View {
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
            rehabilitationViewModel.startMotionTracking()
        }
        .preferredColorScheme(.light)
    }
}

// MARK: - Data Models
struct BalanceMetrics: Codable {
    let centerOfPressure: CGPoint
    let swayArea: Double
    let swayVelocity: Double
    let stabilityScore: Double
    let fallRiskIndex: Double
    let timestamp: Date
    
    init(centerOfPressure: CGPoint, swayArea: Double, swayVelocity: Double, stabilityScore: Double, fallRiskIndex: Double) {
        self.centerOfPressure = centerOfPressure
        self.swayArea = swayArea
        self.swayVelocity = swayVelocity
        self.stabilityScore = stabilityScore
        self.fallRiskIndex = fallRiskIndex
        self.timestamp = Date()
    }
}

struct GaitMetrics: Codable {
    let stepLength: Double
    let cadence: Double
    let symmetry: Double
    let strideLength: Double
    let walkingSpeed: Double
    let timestamp: Date
    
    init(stepLength: Double, cadence: Double, symmetry: Double, strideLength: Double, walkingSpeed: Double) {
        self.stepLength = stepLength
        self.cadence = cadence
        self.symmetry = symmetry
        self.strideLength = strideLength
        self.walkingSpeed = walkingSpeed
        self.timestamp = Date()
    }
}

struct VRTrackingData: Codable {
    let footPosition: CGPoint
    let torsoPosition: CGPoint
    let footVelocity: CGVector
    let torsoVelocity: CGVector
    let balanceOffset: Double
    let timestamp: Date
    
    init(footPosition: CGPoint, torsoPosition: CGPoint, footVelocity: CGVector, torsoVelocity: CGVector, balanceOffset: Double) {
        self.footPosition = footPosition
        self.torsoPosition = torsoPosition
        self.footVelocity = footVelocity
        self.torsoVelocity = torsoVelocity
        self.balanceOffset = balanceOffset
        self.timestamp = Date()
    }
}

enum ExerciseType: String, CaseIterable, Codable {
    case gaitTraining = "Gait Training"
    case balanceExercise = "Balance Exercise"
    case stabilityChallenge = "Stability Challenge"
    case fallPrevention = "Fall Prevention"
    
    var description: String {
        switch self {
        case .gaitTraining:
            return "Improve walking patterns and stride length"
        case .balanceExercise:
            return "Enhance balance and postural control"
        case .stabilityChallenge:
            return "Challenge stability with dynamic movements"
        case .fallPrevention:
            return "Reduce fall risk through targeted exercises"
        }
    }
    
    var estimatedDuration: String {
        switch self {
        case .gaitTraining: return "15-20 minutes"
        case .balanceExercise: return "10-15 minutes"
        case .stabilityChallenge: return "20-25 minutes"
        case .fallPrevention: return "15-20 minutes"
        }
    }
    
    var focusArea: String {
        switch self {
        case .gaitTraining: return "Walking mechanics, stride length, symmetry"
        case .balanceExercise: return "Postural control, center of pressure"
        case .stabilityChallenge: return "Dynamic balance, reaction time"
        case .fallPrevention: return "Fall risk reduction, safety awareness"
        }
    }
}

enum ExerciseDifficulty: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    var multiplier: Double {
        switch self {
        case .beginner: return 0.7
        case .intermediate: return 1.0
        case .advanced: return 1.3
        }
    }
}

struct ExerciseSession: Codable, Identifiable {
    let id = UUID()
    let type: ExerciseType
    let difficulty: ExerciseDifficulty
    let startTime: Date
    let endTime: Date?
    let duration: TimeInterval
    let overallScore: Double
    let balanceMetrics: [BalanceMetrics]
    let gaitMetrics: [GaitMetrics]
    let vrTrackingData: [VRTrackingData]
    let mlRecommendations: [String]
    
    var isActive: Bool {
        return endTime == nil
    }
}

struct RehabilitationProgress: Codable {
    let totalSessions: Int
    let averageScore: Double
    let improvementRate: Double
    let lastSessionDate: Date?
    let recommendedNextExercise: ExerciseType?
    let fallRiskTrend: String
}

struct MLPrediction: Codable {
    let recommendedDifficulty: ExerciseDifficulty
    let nextExerciseType: ExerciseType
    let fallRiskAssessment: String
    let progressForecast: String
    let confidence: Double
}

// MARK: - Extensions for Codable
extension CGPoint: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        self.init(x: x, y: y)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
    
    private enum CodingKeys: String, CodingKey {
        case x, y
    }
}

extension CGVector: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dx = try container.decode(CGFloat.self, forKey: .dx)
        let dy = try container.decode(CGFloat.self, forKey: .dy)
        self.init(dx: dx, dy: dy)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(dx, forKey: .dx)
        try container.encode(dy, forKey: .dy)
    }
    
    private enum CodingKeys: String, CodingKey {
        case dx, dy
    }
}

// MARK: - Services
class VRService: ObservableObject {
    @Published var isConnected = false
    @Published var isTracking = false
    @Published var currentTrackingData: VRTrackingData?
    
    private let motionManager = CMMotionManager()
    private var timer: Timer?
    
    func startTracking() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion not available")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTrackingData()
        }
        
        isTracking = true
        isConnected = true
    }
    
    func stopTracking() {
        motionManager.stopDeviceMotionUpdates()
        timer?.invalidate()
        timer = nil
        isTracking = false
    }
    
    private func updateTrackingData() {
        guard let motion = motionManager.deviceMotion else { return }
        
        // Simulate VR tracking data using device motion
        let footPosition = CGPoint(x: motion.attitude.roll * 100, y: motion.attitude.pitch * 100)
        let torsoPosition = CGPoint(x: motion.attitude.roll * 50, y: motion.attitude.pitch * 50)
        let footVelocity = CGVector(dx: motion.rotationRate.x, dy: motion.rotationRate.y)
        let torsoVelocity = CGVector(dx: motion.rotationRate.x * 0.5, dy: motion.rotationRate.y * 0.5)
        let balanceOffset = sqrt(pow(motion.attitude.roll, 2) + pow(motion.attitude.pitch, 2))
        
        currentTrackingData = VRTrackingData(
            footPosition: footPosition,
            torsoPosition: torsoPosition,
            footVelocity: footVelocity,
            torsoVelocity: torsoVelocity,
            balanceOffset: balanceOffset
        )
    }
    
    func calibrate() {
        // Simulate calibration process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isConnected = true
        }
    }
}

class MLService: ObservableObject {
    @Published var currentPrediction: MLPrediction?
    
    func predictDifficulty(currentMetrics: BalanceMetrics, gaitMetrics: GaitMetrics) -> ExerciseDifficulty {
        let stabilityScore = currentMetrics.stabilityScore
        let fallRisk = currentMetrics.fallRiskIndex
        
        if stabilityScore > 0.8 && fallRisk < 0.3 {
            return .advanced
        } else if stabilityScore > 0.6 && fallRisk < 0.5 {
            return .intermediate
        } else {
            return .beginner
        }
    }
    
    func getRecommendations(currentSession: ExerciseSession) -> [String] {
        var recommendations: [String] = []
        
        if let lastBalance = currentSession.balanceMetrics.last {
            if lastBalance.stabilityScore < 0.5 {
                recommendations.append("Focus on maintaining center of gravity")
            }
            if lastBalance.fallRiskIndex > 0.7 {
                recommendations.append("Consider reducing exercise intensity")
            }
        }
        
        if let lastGait = currentSession.gaitMetrics.last {
            if lastGait.symmetry < 0.8 {
                recommendations.append("Work on improving gait symmetry")
            }
            if lastGait.walkingSpeed < 0.5 {
                recommendations.append("Gradually increase walking speed")
            }
        }
        
        return recommendations
    }
    
    func assessFallRisk(balanceMetrics: [BalanceMetrics]) -> String {
        guard let latest = balanceMetrics.last else { return "Insufficient data" }
        
        if latest.fallRiskIndex > 0.8 {
            return "High Risk - Consider medical consultation"
        } else if latest.fallRiskIndex > 0.6 {
            return "Moderate Risk - Focus on balance exercises"
        } else if latest.fallRiskIndex > 0.4 {
            return "Low Risk - Continue current program"
        } else {
            return "Very Low Risk - Excellent progress"
        }
    }
}

class HealthKitService: ObservableObject {
    @Published var isAuthorized = false
    @Published var isHealthKitAvailable = false
    
    func requestAuthorization() {
        // For now, disable HealthKit completely to avoid crashes
        print("HealthKit disabled - app will work without HealthKit integration")
        DispatchQueue.main.async {
            self.isAuthorized = false
            self.isHealthKitAvailable = false
        }
    }
    
    func saveSession(_ session: ExerciseSession) {
        // HealthKit is disabled for now
        print("Session completed - HealthKit integration disabled")
        print("Session: \(session.type.rawValue) - \(session.difficulty.rawValue)")
        print("Duration: \(session.duration / 60) minutes")
        print("Score: \(session.overallScore)")
    }
}

// MARK: - ViewModels
class RehabilitationViewModel: ObservableObject {
    @Published var currentSession: ExerciseSession?
    @Published var sessionHistory: [ExerciseSession] = []
    @Published var currentBalanceMetrics: BalanceMetrics?
    @Published var currentGaitMetrics: GaitMetrics?
    @Published var isSessionActive = false
    @Published var sessionStartTime: Date?
    @Published var mlRecommendations: [String] = []
    
    private let motionManager = CMMotionManager()
    private let vrService = VRService()
    private let mlService = MLService()
    private let healthKitService = HealthKitService()
    
    private var balanceMetrics: [BalanceMetrics] = []
    private var gaitMetrics: [GaitMetrics] = []
    private var vrTrackingData: [VRTrackingData] = []
    
    init() {
        startMotionTracking()
    }
    
    func startMotionTracking() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion not available")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let motion = motion, error == nil else { return }
            self?.updateMetrics(with: motion)
        }
    }
    
    private func updateMetrics(with motion: CMDeviceMotion) {
        // Calculate balance metrics
        let centerOfPressure = CGPoint(
            x: motion.attitude.roll * 100,
            y: motion.attitude.pitch * 100
        )
        
        let swayArea = abs(motion.attitude.roll) * abs(motion.attitude.pitch) * 1000
        let swayVelocity = sqrt(pow(motion.rotationRate.x, 2) + pow(motion.rotationRate.y, 2))
        let stabilityScore = max(0, 1 - swayVelocity / 10)
        let fallRiskIndex = min(1, swayVelocity / 5)
        
        let balanceMetrics = BalanceMetrics(
            centerOfPressure: centerOfPressure,
            swayArea: swayArea,
            swayVelocity: swayVelocity,
            stabilityScore: stabilityScore,
            fallRiskIndex: fallRiskIndex
        )
        
        // Calculate gait metrics (simplified)
        let stepLength = 0.7 + (stabilityScore * 0.3)
        let cadence = 100 + (stabilityScore * 20)
        let symmetry = 0.8 + (stabilityScore * 0.2)
        let strideLength = stepLength * 2
        let walkingSpeed = stepLength * cadence / 60
        
        let gaitMetrics = GaitMetrics(
            stepLength: stepLength,
            cadence: cadence,
            symmetry: symmetry,
            strideLength: strideLength,
            walkingSpeed: walkingSpeed
        )
        
        DispatchQueue.main.async {
            self.currentBalanceMetrics = balanceMetrics
            self.currentGaitMetrics = gaitMetrics
            
            if self.isSessionActive {
                self.balanceMetrics.append(balanceMetrics)
                self.gaitMetrics.append(gaitMetrics)
                
                if let vrData = self.vrService.currentTrackingData {
                    self.vrTrackingData.append(vrData)
                }
            }
        }
    }
    
    func startSession(type: ExerciseType, difficulty: ExerciseDifficulty) {
        sessionStartTime = Date()
        isSessionActive = true
        
        currentSession = ExerciseSession(
            type: type,
            difficulty: difficulty,
            startTime: Date(),
            endTime: nil,
            duration: 0,
            overallScore: 0,
            balanceMetrics: [],
            gaitMetrics: [],
            vrTrackingData: [],
            mlRecommendations: []
        )
        
        balanceMetrics.removeAll()
        gaitMetrics.removeAll()
        vrTrackingData.removeAll()
        
        vrService.startTracking()
    }
    
    func endSession() {
        guard let session = currentSession, isSessionActive else { return }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(session.startTime)
        
        // Calculate overall score
        let avgStability = balanceMetrics.map { $0.stabilityScore }.reduce(0, +) / Double(max(1, balanceMetrics.count))
        let avgFallRisk = balanceMetrics.map { $0.fallRiskIndex }.reduce(0, +) / Double(max(1, balanceMetrics.count))
        let avgSymmetry = gaitMetrics.map { $0.symmetry }.reduce(0, +) / Double(max(1, gaitMetrics.count))
        
        let overallScore = (avgStability * 0.4 + (1 - avgFallRisk) * 0.3 + avgSymmetry * 0.3) * 100
        
        // Get ML recommendations
        mlRecommendations = mlService.getRecommendations(currentSession: session)
        
        let completedSession = ExerciseSession(
            type: session.type,
            difficulty: session.difficulty,
            startTime: session.startTime,
            endTime: endTime,
            duration: duration,
            overallScore: overallScore,
            balanceMetrics: balanceMetrics,
            gaitMetrics: gaitMetrics,
            vrTrackingData: vrTrackingData,
            mlRecommendations: mlRecommendations
        )
        
        sessionHistory.append(completedSession)
        currentSession = nil
        isSessionActive = false
        sessionStartTime = nil
        
        vrService.stopTracking()
        healthKitService.saveSession(completedSession)
    }
    
    var progress: RehabilitationProgress {
        let totalSessions = sessionHistory.count
        let averageScore = sessionHistory.map { $0.overallScore }.reduce(0, +) / Double(max(1, totalSessions))
        let lastSession = sessionHistory.last
        
        let improvementRate = totalSessions > 1 ? 
            (sessionHistory.last?.overallScore ?? 0) - (sessionHistory.first?.overallScore ?? 0) : 0
        
        let fallRiskTrend = lastSession?.balanceMetrics.last?.fallRiskIndex ?? 0 > 0.6 ? "High" : "Low"
        
        return RehabilitationProgress(
            totalSessions: totalSessions,
            averageScore: averageScore,
            improvementRate: improvementRate,
            lastSessionDate: lastSession?.startTime,
            recommendedNextExercise: .gaitTraining,
            fallRiskTrend: fallRiskTrend
        )
    }
}

// MARK: - Views
struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EnhancedMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with icon
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(color)
                }
                
                Spacer()
                
                // Progress indicator
                ZStack {
                    Circle()
                        .stroke(color.opacity(0.2), lineWidth: 4)
                        .frame(width: 32, height: 32)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
            }
            
            // Value and unit
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .bottom, spacing: 4) {
                    Text(value)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    
                    Text(unit)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: color.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ProgressCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(color)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: color.opacity(0.1), radius: 6, x: 0, y: 3)
        )
    }
}

struct RehabilitationView: View {
    @EnvironmentObject var rehabilitationViewModel: RehabilitationViewModel
    @EnvironmentObject var healthKitService: HealthKitService
    @State private var showingExerciseSelection = false
    @State private var showingSessionSummary = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Section with Session Status
                    VStack(spacing: 20) {
                        // Status Card
                        VStack(spacing: 16) {
                            HStack {
                                // Animated Status Icon
                                ZStack {
                                    Circle()
                                        .fill(rehabilitationViewModel.isSessionActive ? 
                                              LinearGradient(colors: [.red.opacity(0.2), .red.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                              LinearGradient(colors: [.green.opacity(0.2), .green.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: rehabilitationViewModel.isSessionActive ? "stop.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 30, weight: .medium))
                                        .foregroundColor(rehabilitationViewModel.isSessionActive ? .red : .green)
                                        .scaleEffect(rehabilitationViewModel.isSessionActive ? 1.1 : 1.0)
                                        .animation(.easeInOut(duration: 0.3), value: rehabilitationViewModel.isSessionActive)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(rehabilitationViewModel.isSessionActive ? "Session Active" : "Ready to Start")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    
                                    if let session = rehabilitationViewModel.currentSession {
                                        Text("\(session.type.rawValue) • \(session.difficulty.rawValue)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("Select an exercise to begin")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                // Action Button
                                if rehabilitationViewModel.isSessionActive {
                                    Button(action: {
                                        rehabilitationViewModel.endSession()
                                        showingSessionSummary = true
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "stop.fill")
                                            Text("End")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(
                                            LinearGradient(colors: [.red, .red.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                                        )
                                        .cornerRadius(25)
                                        .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                                    }
                                } else {
                                    Button(action: {
                                        showingExerciseSelection = true
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "play.fill")
                                            Text("Start Session")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(
                                            LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                                        )
                                        .cornerRadius(25)
                                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                                    }
                                }
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                    }
                    
                    // Real-time Metrics
                    if rehabilitationViewModel.isSessionActive {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("Real-time Metrics")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Spacer()
                                
                                // Live indicator
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(.green)
                                        .frame(width: 8, height: 8)
                                        .scaleEffect(1.2)
                                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: rehabilitationViewModel.isSessionActive)
                                    
                                    Text("LIVE")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                }
                            }
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                                if let balance = rehabilitationViewModel.currentBalanceMetrics {
                                    EnhancedMetricCard(
                                        title: "Stability Score",
                                        value: String(format: "%.1f", balance.stabilityScore * 100),
                                        unit: "%",
                                        icon: "target",
                                        color: balance.stabilityScore > 0.7 ? .green : balance.stabilityScore > 0.5 ? .orange : .red,
                                        progress: balance.stabilityScore
                                    )
                                    
                                    EnhancedMetricCard(
                                        title: "Fall Risk",
                                        value: String(format: "%.1f", balance.fallRiskIndex * 100),
                                        unit: "%",
                                        icon: "exclamationmark.triangle",
                                        color: balance.fallRiskIndex < 0.3 ? .green : balance.fallRiskIndex < 0.6 ? .orange : .red,
                                        progress: 1 - balance.fallRiskIndex
                                    )
                                }
                                
                                if let gait = rehabilitationViewModel.currentGaitMetrics {
                                    EnhancedMetricCard(
                                        title: "Walking Speed",
                                        value: String(format: "%.1f", gait.walkingSpeed),
                                        unit: "m/s",
                                        icon: "figure.walk",
                                        color: gait.walkingSpeed > 1.0 ? .green : gait.walkingSpeed > 0.7 ? .orange : .red,
                                        progress: min(gait.walkingSpeed / 1.5, 1.0)
                                    )
                                    
                                    EnhancedMetricCard(
                                        title: "Gait Symmetry",
                                        value: String(format: "%.1f", gait.symmetry * 100),
                                        unit: "%",
                                        icon: "arrow.left.and.right",
                                        color: gait.symmetry > 0.8 ? .green : gait.symmetry > 0.6 ? .orange : .red,
                                        progress: gait.symmetry
                                    )
                                }
                            }
                        }
                    }
                    
                    // ML Recommendations
                    if !rehabilitationViewModel.mlRecommendations.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                    .font(.title2)
                                    .foregroundColor(.purple)
                                
                                Text("AI Recommendations")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Spacer()
                            }
                            
                            VStack(spacing: 12) {
                                ForEach(Array(rehabilitationViewModel.mlRecommendations.enumerated()), id: \.offset) { index, recommendation in
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(.purple.opacity(0.2))
                                                .frame(width: 32, height: 32)
                                            
                                            Text("\(index + 1)")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.purple)
                                        }
                                        
                                        Text(recommendation)
                                            .font(.subheadline)
                                            .multilineTextAlignment(.leading)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.ultraThinMaterial)
                                    )
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .purple.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                    }
                    
                    // Progress Overview
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            Text("Progress Overview")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                        }
                        
                        let progress = rehabilitationViewModel.progress
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            ProgressCard(
                                title: "Total Sessions",
                                value: "\(progress.totalSessions)",
                                icon: "number.circle.fill",
                                color: .blue
                            )
                            
                            ProgressCard(
                                title: "Average Score",
                                value: String(format: "%.1f", progress.averageScore),
                                icon: "star.fill",
                                color: progress.averageScore > 70 ? .green : progress.averageScore > 50 ? .orange : .red
                            )
                            
                            ProgressCard(
                                title: "Improvement",
                                value: String(format: "%.1f", progress.improvementRate),
                                icon: "arrow.up.circle.fill",
                                color: progress.improvementRate > 0 ? .green : .red
                            )
                            
                            ProgressCard(
                                title: "Fall Risk",
                                value: progress.fallRiskTrend,
                                icon: "exclamationmark.triangle.fill",
                                color: progress.fallRiskTrend == "Low" ? .green : .red
                            )
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .blue.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                }
                .padding()
            }
            .navigationTitle("PNVR Rehabilitation")
            .navigationBarTitleDisplayMode(.large)
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .sheet(isPresented: $showingExerciseSelection) {
                ExerciseSelectionView()
            }
            .sheet(isPresented: $showingSessionSummary) {
                SessionSummaryView()
            }
        }
    }
}

struct ExerciseSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var rehabilitationViewModel: RehabilitationViewModel
    @State private var selectedType: ExerciseType = .gaitTraining
    @State private var selectedDifficulty: ExerciseDifficulty = .beginner
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Exercise Type Selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("Select Exercise Type")
                        .font(.headline)
                    
                    ForEach(ExerciseType.allCases, id: \.self) { type in
                        ExerciseTypeCard(
                            type: type,
                            isSelected: selectedType == type,
                            onTap: { selectedType = type }
                        )
                    }
                }
                
                // Difficulty Selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("Select Difficulty")
                        .font(.headline)
                    
                    ForEach(ExerciseDifficulty.allCases, id: \.self) { difficulty in
                        DifficultyCard(
                            difficulty: difficulty,
                            isSelected: selectedDifficulty == difficulty,
                            onTap: { selectedDifficulty = difficulty }
                        )
                    }
                }
                
                Spacer()
                
                Button("Start Session") {
                    rehabilitationViewModel.startSession(type: selectedType, difficulty: selectedDifficulty)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedType == nil || selectedDifficulty == nil)
            }
            .padding()
            .navigationTitle("Exercise Selection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ExerciseTypeCard: View {
    let type: ExerciseType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(type.rawValue)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                    }
                }
                
                Text(type.description)
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                
                HStack {
                    Label(type.estimatedDuration, systemImage: "clock")
                    Spacer()
                    Label(type.focusArea, systemImage: "target")
                }
                .font(.caption)
                .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
            }
            .padding()
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DifficultyCard: View {
    let difficulty: ExerciseDifficulty
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(difficulty.rawValue)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text("Intensity: \(Int(difficulty.multiplier * 100))%")
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SessionSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var rehabilitationViewModel: RehabilitationViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let session = rehabilitationViewModel.sessionHistory.last {
                        // Overview
                        SummaryCard(title: "Session Overview") {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Exercise Type:")
                                    Spacer()
                                    Text(session.type.rawValue)
                                        .fontWeight(.semibold)
                                }
                                
                                HStack {
                                    Text("Difficulty:")
                                    Spacer()
                                    Text(session.difficulty.rawValue)
                                        .fontWeight(.semibold)
                                }
                                
                                HStack {
                                    Text("Duration:")
                                    Spacer()
                                    Text(String(format: "%.1f min", session.duration / 60))
                                        .fontWeight(.semibold)
                                }
                                
                                HStack {
                                    Text("Overall Score:")
                                    Spacer()
                                    Text(String(format: "%.1f", session.overallScore))
                                        .fontWeight(.semibold)
                                        .foregroundColor(session.overallScore > 70 ? .green : session.overallScore > 50 ? .orange : .red)
                                }
                            }
                        }
                        
                        // Performance Metrics
                        SummaryCard(title: "Performance Metrics") {
                            VStack(spacing: 12) {
                                let avgStability = session.balanceMetrics.map({ $0.stabilityScore }).reduce(0, +) / Double(max(1, session.balanceMetrics.count))
                                MetricRow(
                                    title: "Average Stability",
                                    value: String(format: "%.1f%%", avgStability * 100),
                                    color: avgStability > 0.7 ? .green : avgStability > 0.5 ? .orange : .red
                                )
                                
                                let avgFallRisk = session.balanceMetrics.map({ $0.fallRiskIndex }).reduce(0, +) / Double(max(1, session.balanceMetrics.count))
                                MetricRow(
                                    title: "Fall Risk",
                                    value: String(format: "%.1f%%", avgFallRisk * 100),
                                    color: avgFallRisk < 0.3 ? .green : avgFallRisk < 0.6 ? .orange : .red
                                )
                                
                                let avgSymmetry = session.gaitMetrics.map({ $0.symmetry }).reduce(0, +) / Double(max(1, session.gaitMetrics.count))
                                MetricRow(
                                    title: "Gait Symmetry",
                                    value: String(format: "%.1f%%", avgSymmetry * 100),
                                    color: avgSymmetry > 0.8 ? .green : avgSymmetry > 0.6 ? .orange : .red
                                )
                                
                                let avgSpeed = session.gaitMetrics.map({ $0.walkingSpeed }).reduce(0, +) / Double(max(1, session.gaitMetrics.count))
                                MetricRow(
                                    title: "Walking Speed",
                                    value: String(format: "%.1f m/s", avgSpeed),
                                    color: avgSpeed > 1.0 ? .green : avgSpeed > 0.7 ? .orange : .red
                                )
                            }
                        }
                        
                        // ML Recommendations
                        if !session.mlRecommendations.isEmpty {
                            SummaryCard(title: "AI Recommendations") {
                                VStack(spacing: 8) {
                                    ForEach(session.mlRecommendations, id: \.self) { recommendation in
                                        RecommendationRow(recommendation: recommendation)
                                    }
                                }
                            }
                        }
                        
                        // Next Steps
                        SummaryCard(title: "Next Steps") {
                            VStack(spacing: 12) {
                                NextStepCard(
                                    title: "Continue Progress",
                                    description: "Keep up the great work! Your stability is improving.",
                                    icon: "arrow.up.circle.fill",
                                    color: .green
                                )
                                
                                NextStepCard(
                                    title: "Next Session",
                                    description: "Try a more challenging exercise to further improve your balance.",
                                    icon: "target",
                                    color: .blue
                                )
                            }
                        }
                    }
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
}

struct SummaryCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            content
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct RecommendationRow: View {
    let recommendation: String
    
    var body: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
            Text(recommendation)
                .font(.subheadline)
            Spacer()
        }
    }
}

struct NextStepCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
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
    }
}

struct MetricsView: View {
    @EnvironmentObject var rehabilitationViewModel: RehabilitationViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Progress Overview
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Progress Overview")
                            .font(.headline)
                        
                        let progress = rehabilitationViewModel.progress
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            MetricCard(
                                title: "Total Sessions",
                                value: "\(progress.totalSessions)",
                                unit: "sessions",
                                color: .blue
                            )
                            
                            MetricCard(
                                title: "Average Score",
                                value: String(format: "%.1f", progress.averageScore),
                                unit: "points",
                                color: progress.averageScore > 70 ? .green : progress.averageScore > 50 ? .orange : .red
                            )
                            
                            MetricCard(
                                title: "Improvement Rate",
                                value: String(format: "%.1f", progress.improvementRate),
                                unit: "points",
                                color: progress.improvementRate > 0 ? .green : .red
                            )
                            
                            MetricCard(
                                title: "Fall Risk Trend",
                                value: progress.fallRiskTrend,
                                unit: "risk",
                                color: progress.fallRiskTrend == "Low" ? .green : .red
                            )
                        }
                    }
                    
                    // Session History
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Sessions")
                            .font(.headline)
                        
                        ForEach(rehabilitationViewModel.sessionHistory.prefix(5)) { session in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(session.type.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Text(String(format: "%.1f", session.overallScore))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(session.overallScore > 70 ? .green : session.overallScore > 50 ? .orange : .red)
                                }
                                
                                HStack {
                                    Text(session.difficulty.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text(String(format: "%.1f min", session.duration / 60))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Metrics & Progress")
        }
    }
}

struct VRIntegrationView: View {
    @EnvironmentObject var rehabilitationViewModel: RehabilitationViewModel
    @StateObject private var vrService = VRService()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Connection Status
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: vrService.isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(vrService.isConnected ? .green : .red)
                            
                            VStack(alignment: .leading) {
                                Text(vrService.isConnected ? "VR Connected" : "VR Disconnected")
                                    .font(.headline)
                                
                                Text(vrService.isTracking ? "Tracking Active" : "Tracking Inactive")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if !vrService.isConnected {
                                Button("Connect") {
                                    vrService.calibrate()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // VR Tracking Data
                    if let trackingData = vrService.currentTrackingData {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("VR Tracking Data")
                                .font(.headline)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                                MetricCard(
                                    title: "Foot Position",
                                    value: String(format: "(%.1f, %.1f)", trackingData.footPosition.x, trackingData.footPosition.y),
                                    unit: "cm",
                                    color: .blue
                                )
                                
                                MetricCard(
                                    title: "Torso Position",
                                    value: String(format: "(%.1f, %.1f)", trackingData.torsoPosition.x, trackingData.torsoPosition.y),
                                    unit: "cm",
                                    color: .green
                                )
                                
                                MetricCard(
                                    title: "Balance Offset",
                                    value: String(format: "%.2f", trackingData.balanceOffset),
                                    unit: "rad",
                                    color: trackingData.balanceOffset < 0.1 ? .green : trackingData.balanceOffset < 0.2 ? .orange : .red
                                )
                                
                                MetricCard(
                                    title: "Foot Velocity",
                                    value: String(format: "%.2f", sqrt(pow(trackingData.footVelocity.dx, 2) + pow(trackingData.footVelocity.dy, 2))),
                                    unit: "rad/s",
                                    color: .purple
                                )
                            }
                        }
                    }
                    
                    // VR Device Info
                    VStack(alignment: .leading, spacing: 16) {
                        Text("VR Device Information")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Device Type:")
                                Spacer()
                                Text("Simulated VR Tracker")
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text("Tracking Mode:")
                                Spacer()
                                Text("Real-time Motion")
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text("Update Rate:")
                                Spacer()
                                Text("10 Hz")
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text("Calibration:")
                                Spacer()
                                Text(vrService.isConnected ? "Complete" : "Required")
                                    .fontWeight(.semibold)
                                    .foregroundColor(vrService.isConnected ? .green : .orange)
                            }
                        }
                        .font(.subheadline)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("VR Integration")
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainContentView()
            .environmentObject(RehabilitationViewModel())
            .environmentObject(HealthKitService())
    }
} 