import Foundation
import CoreMotion
import HealthKit

// MARK: - Balance Metrics
struct BalanceMetrics: Codable, Identifiable {
    let id = UUID()
    let timestamp: Date
    let centerOfPressure: CGPoint
    let swayArea: Double
    let swayVelocity: Double
    let stabilityScore: Double
    let fallRiskIndex: Double
    
    init(timestamp: Date = Date(), centerOfPressure: CGPoint, swayArea: Double, swayVelocity: Double, stabilityScore: Double, fallRiskIndex: Double) {
        self.timestamp = timestamp
        self.centerOfPressure = centerOfPressure
        self.swayArea = swayArea
        self.swayVelocity = swayVelocity
        self.stabilityScore = stabilityScore
        self.fallRiskIndex = fallRiskIndex
    }
}

// MARK: - Gait Metrics
struct GaitMetrics: Codable, Identifiable {
    let id = UUID()
    let timestamp: Date
    let stepLength: Double
    let stepTime: Double
    let cadence: Double
    let gaitSymmetry: Double
    let strideLength: Double
    let walkingSpeed: Double
    
    init(timestamp: Date = Date(), stepLength: Double, stepTime: Double, cadence: Double, gaitSymmetry: Double, strideLength: Double, walkingSpeed: Double) {
        self.timestamp = timestamp
        self.stepLength = stepLength
        self.stepTime = stepTime
        self.cadence = cadence
        self.gaitSymmetry = gaitSymmetry
        self.strideLength = strideLength
        self.walkingSpeed = walkingSpeed
    }
}

// MARK: - VR Tracking Data
struct VRTrackingData: Codable, Identifiable {
    let id = UUID()
    let timestamp: Date
    let footPosition: CGPoint
    let torsoPosition: CGPoint
    let footVelocity: CGVector
    let torsoVelocity: CGVector
    let balanceOffset: Double
    
    init(timestamp: Date = Date(), footPosition: CGPoint, torsoPosition: CGPoint, footVelocity: CGVector, torsoVelocity: CGVector, balanceOffset: Double) {
        self.timestamp = timestamp
        self.footPosition = footPosition
        self.torsoPosition = torsoPosition
        self.footVelocity = footVelocity
        self.torsoVelocity = torsoVelocity
        self.balanceOffset = balanceOffset
    }
}

// MARK: - Exercise Session
struct ExerciseSession: Codable, Identifiable {
    let id = UUID()
    let startTime: Date
    let endTime: Date?
    let exerciseType: ExerciseType
    let difficulty: ExerciseDifficulty
    let balanceMetrics: [BalanceMetrics]
    let gaitMetrics: [GaitMetrics]
    let vrTrackingData: [VRTrackingData]
    let overallScore: Double
    let duration: TimeInterval
    
    init(startTime: Date = Date(), exerciseType: ExerciseType, difficulty: ExerciseDifficulty) {
        self.startTime = startTime
        self.endTime = nil
        self.exerciseType = exerciseType
        self.difficulty = difficulty
        self.balanceMetrics = []
        self.gaitMetrics = []
        self.vrTrackingData = []
        self.overallScore = 0.0
        self.duration = 0.0
    }
}

// MARK: - Exercise Types
enum ExerciseType: String, CaseIterable, Codable {
    case staticBalance = "Static Balance"
    case dynamicBalance = "Dynamic Balance"
    case gaitTraining = "Gait Training"
    case obstacleCourse = "Obstacle Course"
    case dualTask = "Dual Task"
    case vestibularTraining = "Vestibular Training"
    
    var description: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .staticBalance: return "figure.stand"
        case .dynamicBalance: return "figure.walk"
        case .gaitTraining: return "figure.walk.circle"
        case .obstacleCourse: return "figure.walk.motion"
        case .dualTask: return "brain.head.profile"
        case .vestibularTraining: return "eye"
        }
    }
}

// MARK: - Exercise Difficulty
enum ExerciseDifficulty: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"
    
    var multiplier: Double {
        switch self {
        case .beginner: return 0.5
        case .intermediate: return 1.0
        case .advanced: return 1.5
        case .expert: return 2.0
        }
    }
}

// MARK: - Rehabilitation Progress
struct RehabilitationProgress: Codable {
    let userId: String
    let startDate: Date
    let currentLevel: ExerciseDifficulty
    let totalSessions: Int
    let averageStabilityScore: Double
    let averageGaitScore: Double
    let fallRiskTrend: [Double]
    let improvementRate: Double
    
    init(userId: String, startDate: Date = Date()) {
        self.userId = userId
        self.startDate = startDate
        self.currentLevel = .beginner
        self.totalSessions = 0
        self.averageStabilityScore = 0.0
        self.averageGaitScore = 0.0
        self.fallRiskTrend = []
        self.improvementRate = 0.0
    }
}

// MARK: - ML Prediction
struct MLPrediction: Codable {
    let predictedDifficulty: ExerciseDifficulty
    let confidence: Double
    let recommendedExercise: ExerciseType
    let riskAssessment: String
    let nextSessionRecommendation: String
    
    init(predictedDifficulty: ExerciseDifficulty, confidence: Double, recommendedExercise: ExerciseType, riskAssessment: String, nextSessionRecommendation: String) {
        self.predictedDifficulty = predictedDifficulty
        self.confidence = confidence
        self.recommendedExercise = recommendedExercise
        self.riskAssessment = riskAssessment
        self.nextSessionRecommendation = nextSessionRecommendation
    }
}

// MARK: - Extensions for Core Graphics
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