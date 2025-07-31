import Foundation
import CoreML
import Accelerate

class MLService: ObservableObject {
    @Published var isModelLoaded = false
    @Published var predictionConfidence: Double = 0.0
    @Published var lastPrediction: MLPrediction?
    
    private var model: MLModel?
    private var trainingData: [TrainingDataPoint] = []
    private var predictionHistory: [MLPrediction] = []
    
    struct TrainingDataPoint {
        let balanceMetrics: BalanceMetrics
        let gaitMetrics: GaitMetrics?
        let sessionHistory: [ExerciseSession]
        let outcome: ExerciseOutcome
    }
    
    enum ExerciseOutcome {
        case success
        case partial
        case failure
        case injury
    }
    
    init() {
        loadModel()
        setupDefaultTrainingData()
    }
    
    // MARK: - Public Methods
    func generatePrediction(
        balanceMetrics: BalanceMetrics?,
        gaitMetrics: GaitMetrics?,
        sessionHistory: [ExerciseSession]
    ) async -> MLPrediction {
        
        // Simulate ML processing time
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        let prediction = await performPrediction(
            balanceMetrics: balanceMetrics,
            gaitMetrics: gaitMetrics,
            sessionHistory: sessionHistory
        )
        
        await MainActor.run {
            self.lastPrediction = prediction
            self.predictionHistory.append(prediction)
        }
        
        return prediction
    }
    
    func adjustDifficulty(
        currentDifficulty: ExerciseDifficulty,
        performance: Double,
        riskLevel: Double
    ) -> ExerciseDifficulty {
        
        // Adaptive difficulty adjustment based on performance and risk
        let performanceThreshold = 0.7
        let riskThreshold = 0.6
        
        if performance > performanceThreshold && riskLevel < riskThreshold {
            // Good performance, low risk - increase difficulty
            return increaseDifficulty(currentDifficulty)
        } else if performance < performanceThreshold || riskLevel > riskThreshold {
            // Poor performance or high risk - decrease difficulty
            return decreaseDifficulty(currentDifficulty)
        } else {
            // Maintain current difficulty
            return currentDifficulty
        }
    }
    
    func updateModel(with sessionData: ExerciseSession) {
        // Update the ML model with new session data
        let trainingPoint = createTrainingDataPoint(from: sessionData)
        trainingData.append(trainingPoint)
        
        // Retrain model periodically
        if trainingData.count % 10 == 0 {
            retrainModel()
        }
    }
    
    // MARK: - Private Methods
    private func loadModel() {
        // In a real implementation, this would load a Core ML model
        // For now, we'll simulate model loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isModelLoaded = true
        }
    }
    
    private func setupDefaultTrainingData() {
        // Create some default training data for the ML model
        let defaultData = createDefaultTrainingData()
        trainingData = defaultData
    }
    
    private func performPrediction(
        balanceMetrics: BalanceMetrics?,
        gaitMetrics: GaitMetrics?,
        sessionHistory: [ExerciseSession]
    ) async -> MLPrediction {
        
        // Extract features from input data
        let features = extractFeatures(
            balanceMetrics: balanceMetrics,
            gaitMetrics: gaitMetrics,
            sessionHistory: sessionHistory
        )
        
        // Perform prediction using ML model
        let prediction = await predictWithModel(features: features)
        
        return prediction
    }
    
    private func extractFeatures(
        balanceMetrics: BalanceMetrics?,
        gaitMetrics: GaitMetrics?,
        sessionHistory: [ExerciseSession]
    ) -> [Double] {
        var features: [Double] = []
        
        // Balance features
        if let balance = balanceMetrics {
            features.append(balance.stabilityScore / 100.0)
            features.append(balance.fallRiskIndex / 100.0)
            features.append(balance.swayArea / 10.0)
            features.append(balance.swayVelocity / 5.0)
        } else {
            features.append(contentsOf: [0.0, 0.0, 0.0, 0.0])
        }
        
        // Gait features
        if let gait = gaitMetrics {
            features.append(gait.gaitSymmetry)
            features.append(gait.walkingSpeed / 2.0)
            features.append(gait.cadence / 120.0)
            features.append(gait.stepLength / 1.0)
        } else {
            features.append(contentsOf: [0.0, 0.0, 0.0, 0.0])
        }
        
        // Session history features
        let recentSessions = Array(sessionHistory.suffix(5))
        let avgScore = recentSessions.map { $0.overallScore }.reduce(0, +) / Double(max(recentSessions.count, 1))
        features.append(avgScore / 100.0)
        
        let sessionCount = Double(sessionHistory.count)
        features.append(min(sessionCount / 50.0, 1.0))
        
        return features
    }
    
    private func predictWithModel(features: [Double]) async -> MLPrediction {
        // Simulate ML model prediction
        let stabilityScore = features[0]
        let fallRisk = features[1]
        let gaitSymmetry = features[4]
        let avgScore = features[8]
        
        // Determine recommended exercise type
        let recommendedExercise = determineRecommendedExercise(
            stabilityScore: stabilityScore,
            fallRisk: fallRisk,
            gaitSymmetry: gaitSymmetry
        )
        
        // Determine difficulty level
        let predictedDifficulty = determineDifficulty(
            stabilityScore: stabilityScore,
            fallRisk: fallRisk,
            avgScore: avgScore
        )
        
        // Calculate confidence
        let confidence = calculateConfidence(features: features)
        
        // Assess risk
        let riskAssessment = assessRisk(fallRisk: fallRisk, stabilityScore: stabilityScore)
        
        // Generate recommendation
        let recommendation = generateRecommendation(
            exercise: recommendedExercise,
            difficulty: predictedDifficulty,
            risk: riskAssessment
        )
        
        return MLPrediction(
            predictedDifficulty: predictedDifficulty,
            confidence: confidence,
            recommendedExercise: recommendedExercise,
            riskAssessment: riskAssessment,
            nextSessionRecommendation: recommendation
        )
    }
    
    private func determineRecommendedExercise(
        stabilityScore: Double,
        fallRisk: Double,
        gaitSymmetry: Double
    ) -> ExerciseType {
        
        if fallRisk > 0.7 {
            return .staticBalance
        } else if stabilityScore < 0.6 {
            return .dynamicBalance
        } else if gaitSymmetry < 0.8 {
            return .gaitTraining
        } else if stabilityScore > 0.8 {
            return .obstacleCourse
        } else {
            return .dualTask
        }
    }
    
    private func determineDifficulty(
        stabilityScore: Double,
        fallRisk: Double,
        avgScore: Double
    ) -> ExerciseDifficulty {
        
        let overallScore = (stabilityScore + (1.0 - fallRisk) + avgScore) / 3.0
        
        if overallScore > 0.8 {
            return .expert
        } else if overallScore > 0.6 {
            return .advanced
        } else if overallScore > 0.4 {
            return .intermediate
        } else {
            return .beginner
        }
    }
    
    private func calculateConfidence(features: [Double]) -> Double {
        // Calculate confidence based on feature consistency and data quality
        let variance = calculateVariance(features)
        let dataQuality = features.filter { $0 > 0 }.count / Double(features.count)
        
        let confidence = (1.0 - variance) * dataQuality
        return max(0.3, min(0.95, confidence))
    }
    
    private func calculateVariance(_ values: [Double]) -> Double {
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDifferences = values.map { pow($0 - mean, 2) }
        let variance = squaredDifferences.reduce(0, +) / Double(values.count)
        return variance
    }
    
    private func assessRisk(fallRisk: Double, stabilityScore: Double) -> String {
        let riskLevel = (fallRisk + (1.0 - stabilityScore)) / 2.0
        
        if riskLevel > 0.7 {
            return "High Risk"
        } else if riskLevel > 0.4 {
            return "Medium Risk"
        } else {
            return "Low Risk"
        }
    }
    
    private func generateRecommendation(
        exercise: ExerciseType,
        difficulty: ExerciseDifficulty,
        risk: String
    ) -> String {
        
        switch (exercise, difficulty, risk) {
        case (.staticBalance, _, "High Risk"):
            return "Focus on basic balance exercises with support"
        case (.gaitTraining, .beginner, _):
            return "Practice walking with assistance if needed"
        case (.obstacleCourse, .expert, "Low Risk"):
            return "Challenge yourself with complex movements"
        default:
            return "Continue with current exercise progression"
        }
    }
    
    private func increaseDifficulty(_ current: ExerciseDifficulty) -> ExerciseDifficulty {
        switch current {
        case .beginner: return .intermediate
        case .intermediate: return .advanced
        case .advanced: return .expert
        case .expert: return .expert
        }
    }
    
    private func decreaseDifficulty(_ current: ExerciseDifficulty) -> ExerciseDifficulty {
        switch current {
        case .beginner: return .beginner
        case .intermediate: return .beginner
        case .advanced: return .intermediate
        case .expert: return .advanced
        }
    }
    
    private func createTrainingDataPoint(from session: ExerciseSession) -> TrainingDataPoint {
        let avgBalanceMetrics = session.balanceMetrics.reduce(
            BalanceMetrics(centerOfPressure: .zero, swayArea: 0, swayVelocity: 0, stabilityScore: 0, fallRiskIndex: 0)
        ) { result, metric in
            BalanceMetrics(
                centerOfPressure: result.centerOfPressure,
                swayArea: result.swayArea + metric.swayArea,
                swayVelocity: result.swayVelocity + metric.swayVelocity,
                stabilityScore: result.stabilityScore + metric.stabilityScore,
                fallRiskIndex: result.fallRiskIndex + metric.fallRiskIndex
            )
        }
        
        let avgGaitMetrics = session.gaitMetrics.isEmpty ? nil : session.gaitMetrics.reduce(
            GaitMetrics(stepLength: 0, stepTime: 0, cadence: 0, gaitSymmetry: 0, strideLength: 0, walkingSpeed: 0)
        ) { result, metric in
            GaitMetrics(
                stepLength: result.stepLength + metric.stepLength,
                stepTime: result.stepTime + metric.stepTime,
                cadence: result.cadence + metric.cadence,
                gaitSymmetry: result.gaitSymmetry + metric.gaitSymmetry,
                strideLength: result.strideLength + metric.strideLength,
                walkingSpeed: result.walkingSpeed + metric.walkingSpeed
            )
        }
        
        let outcome: ExerciseOutcome = session.overallScore > 80 ? .success :
                                     session.overallScore > 60 ? .partial :
                                     session.overallScore > 40 ? .failure : .injury
        
        return TrainingDataPoint(
            balanceMetrics: avgBalanceMetrics,
            gaitMetrics: avgGaitMetrics,
            sessionHistory: [session],
            outcome: outcome
        )
    }
    
    private func createDefaultTrainingData() -> [TrainingDataPoint] {
        // Create synthetic training data for demonstration
        var data: [TrainingDataPoint] = []
        
        for i in 0..<50 {
            let stabilityScore = Double.random(in: 0.3...1.0)
            let fallRisk = Double.random(in: 0.0...0.7)
            let gaitSymmetry = Double.random(in: 0.6...1.0)
            
            let balanceMetrics = BalanceMetrics(
                centerOfPressure: CGPoint(x: Double.random(in: -50...50), y: Double.random(in: -50...50)),
                swayArea: Double.random(in: 0.1...2.0),
                swayVelocity: Double.random(in: 0.01...0.5),
                stabilityScore: stabilityScore * 100,
                fallRiskIndex: fallRisk * 100
            )
            
            let gaitMetrics = GaitMetrics(
                stepLength: Double.random(in: 0.4...0.8),
                stepTime: Double.random(in: 0.8...1.2),
                cadence: Double.random(in: 80...120),
                gaitSymmetry: gaitSymmetry,
                strideLength: Double.random(in: 0.8...1.6),
                walkingSpeed: Double.random(in: 0.8...1.5)
            )
            
            let outcome: ExerciseOutcome = stabilityScore > 0.7 && fallRisk < 0.3 ? .success :
                                         stabilityScore > 0.5 && fallRisk < 0.5 ? .partial :
                                         stabilityScore > 0.3 ? .failure : .injury
            
            let trainingPoint = TrainingDataPoint(
                balanceMetrics: balanceMetrics,
                gaitMetrics: gaitMetrics,
                sessionHistory: [],
                outcome: outcome
            )
            
            data.append(trainingPoint)
        }
        
        return data
    }
    
    private func retrainModel() {
        // Simulate model retraining
        print("Retraining ML model with \(trainingData.count) data points")
    }
    
    // MARK: - Analytics
    func getPredictionAccuracy() -> Double {
        // Calculate prediction accuracy based on historical data
        guard !predictionHistory.isEmpty else { return 0.0 }
        
        let correctPredictions = predictionHistory.filter { prediction in
            // Compare prediction with actual outcomes
            // This is a simplified calculation
            return prediction.confidence > 0.7
        }.count
        
        return Double(correctPredictions) / Double(predictionHistory.count)
    }
    
    func getModelPerformance() -> [String: Double] {
        return [
            "accuracy": getPredictionAccuracy(),
            "confidence": predictionHistory.map { $0.confidence }.reduce(0, +) / Double(max(predictionHistory.count, 1)),
            "training_samples": Double(trainingData.count)
        ]
    }
} 