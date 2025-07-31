import Foundation
import CoreMotion
import Combine
import SwiftUI

@MainActor
class RehabilitationViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentSession: ExerciseSession?
    @Published var isSessionActive = false
    @Published var currentBalanceMetrics: BalanceMetrics?
    @Published var currentGaitMetrics: GaitMetrics?
    @Published var currentVRTrackingData: VRTrackingData?
    @Published var selectedExerciseType: ExerciseType = .staticBalance
    @Published var selectedDifficulty: ExerciseDifficulty = .beginner
    @Published var sessionHistory: [ExerciseSession] = []
    @Published var progress: RehabilitationProgress?
    @Published var mlPrediction: MLPrediction?
    @Published var isMotionTrackingActive = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let motionManager = CMMotionManager()
    private let motionQueue = OperationQueue()
    private var cancellables = Set<AnyCancellable>()
    private let mlService = MLService()
    private let vrService = VRService()
    
    // MARK: - Motion Data
    private var accelerometerData: [CMAccelerometerData] = []
    private var gyroscopeData: [CMGyroData] = []
    private var deviceMotionData: [CMDeviceMotion] = []
    
    init() {
        setupMotionManager()
        loadSessionHistory()
        loadProgress()
    }
    
    // MARK: - Session Management
    func startSession(exerciseType: ExerciseType, difficulty: ExerciseDifficulty) {
        currentSession = ExerciseSession(exerciseType: exerciseType, difficulty: difficulty)
        isSessionActive = true
        startMotionTracking()
        startVRTracking()
        
        // Generate ML prediction for session
        generateMLPrediction()
    }
    
    func endSession() {
        guard var session = currentSession else { return }
        
        session.endTime = Date()
        session.duration = session.endTime!.timeIntervalSince(session.startTime)
        session.overallScore = calculateOverallScore()
        
        sessionHistory.append(session)
        saveSessionHistory()
        updateProgress(with: session)
        
        isSessionActive = false
        stopMotionTracking()
        stopVRTracking()
        
        currentSession = nil
    }
    
    // MARK: - Motion Tracking
    func startMotionTracking() {
        guard motionManager.isDeviceMotionAvailable else {
            errorMessage = "Device motion not available"
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 0.1 // 10Hz
        motionManager.startDeviceMotionUpdates(to: motionQueue) { [weak self] motion, error in
            guard let self = self, let motion = motion, error == nil else { return }
            
            Task { @MainActor in
                self.processMotionData(motion)
            }
        }
        
        isMotionTrackingActive = true
    }
    
    func stopMotionTracking() {
        motionManager.stopDeviceMotionUpdates()
        isMotionTrackingActive = false
    }
    
    private func setupMotionManager() {
        motionQueue.maxConcurrentOperationCount = 1
        motionQueue.qualityOfService = .userInteractive
    }
    
    private func processMotionData(_ motion: CMDeviceMotion) {
        deviceMotionData.append(motion)
        
        // Keep only last 100 data points
        if deviceMotionData.count > 100 {
            deviceMotionData.removeFirst()
        }
        
        // Calculate balance metrics
        let balanceMetrics = calculateBalanceMetrics(from: motion)
        currentBalanceMetrics = balanceMetrics
        
        // Calculate gait metrics if walking
        if isWalking(motion) {
            let gaitMetrics = calculateGaitMetrics(from: motion)
            currentGaitMetrics = gaitMetrics
        }
        
        // Update VR tracking data
        updateVRTrackingData(with: motion)
        
        // Update current session
        updateCurrentSession()
    }
    
    // MARK: - Balance Metrics Calculation
    private func calculateBalanceMetrics(from motion: CMDeviceMotion) -> BalanceMetrics {
        let gravity = motion.gravity
        let userAcceleration = motion.userAcceleration
        
        // Calculate center of pressure (simplified)
        let centerOfPressure = CGPoint(
            x: CGFloat(gravity.x * 100),
            y: CGFloat(gravity.y * 100)
        )
        
        // Calculate sway area
        let swayArea = sqrt(pow(gravity.x, 2) + pow(gravity.y, 2)) * 100
        
        // Calculate sway velocity
        let swayVelocity = sqrt(pow(userAcceleration.x, 2) + pow(userAcceleration.y, 2))
        
        // Calculate stability score (0-100)
        let stabilityScore = max(0, 100 - (swayArea * 10))
        
        // Calculate fall risk index (0-100, higher = more risk)
        let fallRiskIndex = min(100, swayArea * 20 + swayVelocity * 50)
        
        return BalanceMetrics(
            centerOfPressure: centerOfPressure,
            swayArea: swayArea,
            swayVelocity: swayVelocity,
            stabilityScore: stabilityScore,
            fallRiskIndex: fallRiskIndex
        )
    }
    
    // MARK: - Gait Metrics Calculation
    private func isWalking(_ motion: CMDeviceMotion) -> Bool {
        let acceleration = motion.userAcceleration
        let magnitude = sqrt(pow(acceleration.x, 2) + pow(acceleration.y, 2) + pow(acceleration.z, 2))
        return magnitude > 0.1 // Threshold for walking detection
    }
    
    private func calculateGaitMetrics(from motion: CMDeviceMotion) -> GaitMetrics {
        // Simplified gait metrics calculation
        let stepLength = Double.random(in: 0.5...0.8) // meters
        let stepTime = Double.random(in: 0.8...1.2) // seconds
        let cadence = 60.0 / stepTime // steps per minute
        let gaitSymmetry = Double.random(in: 0.7...1.0) // 0-1 scale
        let strideLength = stepLength * 2
        let walkingSpeed = stepLength / stepTime // m/s
        
        return GaitMetrics(
            stepLength: stepLength,
            stepTime: stepTime,
            cadence: cadence,
            gaitSymmetry: gaitSymmetry,
            strideLength: strideLength,
            walkingSpeed: walkingSpeed
        )
    }
    
    // MARK: - VR Integration
    private func startVRTracking() {
        vrService.startTracking()
    }
    
    private func stopVRTracking() {
        vrService.stopTracking()
    }
    
    private func updateVRTrackingData(with motion: CMDeviceMotion) {
        let footPosition = CGPoint(x: CGFloat(motion.gravity.x * 50), y: CGFloat(motion.gravity.y * 50))
        let torsoPosition = CGPoint(x: CGFloat(motion.gravity.x * 30), y: CGFloat(motion.gravity.y * 30))
        let footVelocity = CGVector(dx: CGFloat(motion.userAcceleration.x), dy: CGFloat(motion.userAcceleration.y))
        let torsoVelocity = CGVector(dx: CGFloat(motion.userAcceleration.x * 0.5), dy: CGFloat(motion.userAcceleration.y * 0.5))
        let balanceOffset = sqrt(pow(motion.gravity.x, 2) + pow(motion.gravity.y, 2))
        
        currentVRTrackingData = VRTrackingData(
            footPosition: footPosition,
            torsoPosition: torsoPosition,
            footVelocity: footVelocity,
            torsoVelocity: torsoVelocity,
            balanceOffset: balanceOffset
        )
    }
    
    // MARK: - Session Updates
    private func updateCurrentSession() {
        guard var session = currentSession else { return }
        
        if let balanceMetrics = currentBalanceMetrics {
            session.balanceMetrics.append(balanceMetrics)
        }
        
        if let gaitMetrics = currentGaitMetrics {
            session.gaitMetrics.append(gaitMetrics)
        }
        
        if let vrData = currentVRTrackingData {
            session.vrTrackingData.append(vrData)
        }
        
        currentSession = session
    }
    
    // MARK: - Scoring
    private func calculateOverallScore() -> Double {
        guard let session = currentSession else { return 0.0 }
        
        let balanceScore = session.balanceMetrics.map { $0.stabilityScore }.reduce(0, +) / Double(max(session.balanceMetrics.count, 1))
        let gaitScore = session.gaitMetrics.map { $0.gaitSymmetry * 100 }.reduce(0, +) / Double(max(session.gaitMetrics.count, 1))
        
        return (balanceScore + gaitScore) / 2.0
    }
    
    // MARK: - ML Integration
    private func generateMLPrediction() {
        Task {
            let prediction = await mlService.generatePrediction(
                balanceMetrics: currentBalanceMetrics,
                gaitMetrics: currentGaitMetrics,
                sessionHistory: sessionHistory
            )
            
            await MainActor.run {
                self.mlPrediction = prediction
            }
        }
    }
    
    // MARK: - Progress Management
    private func updateProgress(with session: ExerciseSession) {
        if progress == nil {
            progress = RehabilitationProgress(userId: "user123")
        }
        
        guard var currentProgress = progress else { return }
        
        currentProgress.totalSessions += 1
        currentProgress.averageStabilityScore = calculateAverageStabilityScore()
        currentProgress.averageGaitScore = calculateAverageGaitScore()
        currentProgress.fallRiskTrend = calculateFallRiskTrend()
        currentProgress.improvementRate = calculateImprovementRate()
        
        progress = currentProgress
        saveProgress()
    }
    
    private func calculateAverageStabilityScore() -> Double {
        let allScores = sessionHistory.flatMap { $0.balanceMetrics }.map { $0.stabilityScore }
        return allScores.reduce(0, +) / Double(max(allScores.count, 1))
    }
    
    private func calculateAverageGaitScore() -> Double {
        let allScores = sessionHistory.flatMap { $0.gaitMetrics }.map { $0.gaitSymmetry * 100 }
        return allScores.reduce(0, +) / Double(max(allScores.count, 1))
    }
    
    private func calculateFallRiskTrend() -> [Double] {
        let recentSessions = Array(sessionHistory.suffix(10))
        return recentSessions.map { session in
            let avgRisk = session.balanceMetrics.map { $0.fallRiskIndex }.reduce(0, +) / Double(max(session.balanceMetrics.count, 1))
            return avgRisk
        }
    }
    
    private func calculateImprovementRate() -> Double {
        guard sessionHistory.count >= 2 else { return 0.0 }
        
        let recentScores = Array(sessionHistory.suffix(5)).map { $0.overallScore }
        let olderScores = Array(sessionHistory.prefix(5)).map { $0.overallScore }
        
        let recentAvg = recentScores.reduce(0, +) / Double(recentScores.count)
        let olderAvg = olderScores.reduce(0, +) / Double(olderScores.count)
        
        return ((recentAvg - olderAvg) / olderAvg) * 100
    }
    
    // MARK: - Data Persistence
    private func saveSessionHistory() {
        // In a real app, this would save to Core Data or UserDefaults
        // For now, we'll just keep it in memory
    }
    
    private func loadSessionHistory() {
        // Load from persistent storage
    }
    
    private func saveProgress() {
        // Save progress to persistent storage
    }
    
    private func loadProgress() {
        // Load progress from persistent storage
    }
} 