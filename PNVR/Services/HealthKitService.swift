import Foundation
import HealthKit
import Combine

class HealthKitService: ObservableObject {
    @Published var isAuthorized = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    
    private let healthStore = HKHealthStore()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - HealthKit Data Types
    private let requiredTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .bodyMass)!,
        HKObjectType.quantityType(forIdentifier: .height)!,
        HKObjectType.categoryType(forIdentifier: .fall)!,
        HKObjectType.quantityType(forIdentifier: .walkingSpeed)!,
        HKObjectType.quantityType(forIdentifier: .walkingStepLength)!
    ]
    
    private let writeTypes: Set<HKSampleType> = [
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .walkingSpeed)!,
        HKObjectType.quantityType(forIdentifier: .walkingStepLength)!
    ]
    
    init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "HealthKit is not available on this device"
            return
        }
        
        healthStore.requestAuthorization(toShare: writeTypes, read: requiredTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthorized = true
                    self?.authorizationStatus = .sharingAuthorized
                    self?.errorMessage = nil
                } else {
                    self?.isAuthorized = false
                    self?.authorizationStatus = .sharingDenied
                    self?.errorMessage = error?.localizedDescription ?? "Authorization failed"
                }
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatus = .notDetermined
            return
        }
        
        for type in requiredTypes {
            let status = healthStore.authorizationStatus(for: type)
            if status == .sharingDenied {
                authorizationStatus = .sharingDenied
                return
            }
        }
        authorizationStatus = .sharingAuthorized
        isAuthorized = true
    }
    
    // MARK: - Data Reading
    func fetchStepCount(for date: Date) async -> Int {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return 0
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: date, end: Calendar.current.date(byAdding: .day, value: 1, to: date), options: .strictStartDate)
        
        do {
            let query = HKStatisticsQuery(quantityType: stepCountType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    print("Error fetching step count: \(error)")
                }
            }
            
            healthStore.execute(query)
            
            // For now, return a simulated value
            return Int.random(in: 5000...15000)
        }
    }
    
    func fetchWalkingDistance(for date: Date) async -> Double {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            return 0.0
        }
        
        // Simulate distance data
        return Double.random(in: 2.0...8.0)
    }
    
    func fetchHeartRate(for date: Date) async -> [HKQuantitySample] {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return []
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: date, end: Calendar.current.date(byAdding: .day, value: 1, to: date), options: .strictStartDate)
        
        do {
            let samples = try await healthStore.samples(for: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil)
            return samples
        } catch {
            print("Error fetching heart rate: \(error)")
            return []
        }
    }
    
    func fetchFallData(for date: Date) async -> [HKCategorySample] {
        guard let fallType = HKCategoryType.categoryType(forIdentifier: .fall) else {
            return []
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: date, end: Calendar.current.date(byAdding: .day, value: 1, to: date), options: .strictStartDate)
        
        do {
            let samples = try await healthStore.samples(for: fallType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil)
            return samples
        } catch {
            print("Error fetching fall data: \(error)")
            return []
        }
    }
    
    // MARK: - Data Writing
    func saveRehabilitationSession(_ session: ExerciseSession) async {
        guard isAuthorized else {
            errorMessage = "HealthKit authorization required"
            return
        }
        
        // Save step count
        if let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            let stepCount = session.gaitMetrics.reduce(0) { $0 + Int($1.cadence * session.duration / 60) }
            let stepQuantity = HKQuantity(unit: HKUnit.count(), doubleValue: Double(stepCount))
            let stepSample = HKQuantitySample(type: stepCountType, quantity: stepQuantity, start: session.startTime, end: session.endTime ?? Date())
            
            do {
                try await healthStore.save(stepSample)
            } catch {
                print("Error saving step count: \(error)")
            }
        }
        
        // Save walking distance
        if let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
            let totalDistance = session.gaitMetrics.reduce(0.0) { $0 + ($1.walkingSpeed * session.duration) }
            let distanceQuantity = HKQuantity(unit: HKUnit.meter(), doubleValue: totalDistance)
            let distanceSample = HKQuantitySample(type: distanceType, quantity: distanceQuantity, start: session.startTime, end: session.endTime ?? Date())
            
            do {
                try await healthStore.save(distanceSample)
            } catch {
                print("Error saving distance: \(error)")
            }
        }
        
        // Save active energy burned
        if let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            let caloriesBurned = calculateCaloriesBurned(for: session)
            let energyQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: caloriesBurned)
            let energySample = HKQuantitySample(type: energyType, quantity: energyQuantity, start: session.startTime, end: session.endTime ?? Date())
            
            do {
                try await healthStore.save(energySample)
            } catch {
                print("Error saving energy: \(error)")
            }
        }
    }
    
    private func calculateCaloriesBurned(for session: ExerciseSession) -> Double {
        // Simplified calorie calculation based on exercise type and duration
        let baseCaloriesPerMinute: Double
        
        switch session.exerciseType {
        case .staticBalance:
            baseCaloriesPerMinute = 2.0
        case .dynamicBalance:
            baseCaloriesPerMinute = 3.5
        case .gaitTraining:
            baseCaloriesPerMinute = 4.0
        case .obstacleCourse:
            baseCaloriesPerMinute = 5.0
        case .dualTask:
            baseCaloriesPerMinute = 4.5
        case .vestibularTraining:
            baseCaloriesPerMinute = 2.5
        }
        
        let durationInMinutes = session.duration / 60.0
        return baseCaloriesPerMinute * durationInMinutes
    }
    
    // MARK: - Health Data Analysis
    func analyzeHealthTrends() async -> HealthTrends {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .month, value: -1, to: endDate) ?? endDate
        
        let stepCounts = await fetchStepCounts(from: startDate, to: endDate)
        let distances = await fetchWalkingDistances(from: startDate, to: endDate)
        let heartRates = await fetchHeartRates(from: startDate, to: endDate)
        let falls = await fetchFalls(from: startDate, to: endDate)
        
        return HealthTrends(
            averageStepsPerDay: stepCounts.reduce(0, +) / Double(stepCounts.count),
            averageDistancePerDay: distances.reduce(0, +) / Double(distances.count),
            averageHeartRate: heartRates.isEmpty ? 0 : heartRates.reduce(0, +) / Double(heartRates.count),
            fallCount: falls.count,
            stepTrend: calculateTrend(stepCounts),
            distanceTrend: calculateTrend(distances)
        )
    }
    
    private func fetchStepCounts(from startDate: Date, to endDate: Date) async -> [Int] {
        var stepCounts: [Int] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let steps = await fetchStepCount(for: currentDate)
            stepCounts.append(steps)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return stepCounts
    }
    
    private func fetchWalkingDistances(from startDate: Date, to endDate: Date) async -> [Double] {
        var distances: [Double] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let distance = await fetchWalkingDistance(for: currentDate)
            distances.append(distance)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return distances
    }
    
    private func fetchHeartRates(from startDate: Date, to endDate: Date) async -> [Double] {
        var heartRates: [Double] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let samples = await fetchHeartRate(for: currentDate)
            let avgHeartRate = samples.map { $0.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) }.reduce(0, +) / Double(max(samples.count, 1))
            heartRates.append(avgHeartRate)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return heartRates
    }
    
    private func fetchFalls(from startDate: Date, to endDate: Date) async -> [HKCategorySample] {
        var falls: [HKCategorySample] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let dayFalls = await fetchFallData(for: currentDate)
            falls.append(contentsOf: dayFalls)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return falls
    }
    
    private func calculateTrend(_ values: [Double]) -> TrendDirection {
        guard values.count >= 2 else { return .stable }
        
        let recent = Array(values.suffix(7)).reduce(0, +) / Double(min(values.count, 7))
        let older = Array(values.prefix(7)).reduce(0, +) / Double(min(values.count, 7))
        
        let change = (recent - older) / older
        
        if change > 0.1 {
            return .increasing
        } else if change < -0.1 {
            return .decreasing
        } else {
            return .stable
        }
    }
    
    // MARK: - HIPAA Compliance
    func exportHealthData() async -> Data? {
        guard isAuthorized else { return nil }
        
        let healthData = HealthDataExport(
            stepCounts: await fetchStepCounts(from: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(), to: Date()),
            distances: await fetchWalkingDistances(from: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(), to: Date()),
            heartRates: await fetchHeartRates(from: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(), to: Date()),
            falls: await fetchFalls(from: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(), to: Date())
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(healthData)
        } catch {
            print("Error encoding health data: \(error)")
            return nil
        }
    }
}

// MARK: - Data Structures
struct HealthTrends {
    let averageStepsPerDay: Double
    let averageDistancePerDay: Double
    let averageHeartRate: Double
    let fallCount: Int
    let stepTrend: TrendDirection
    let distanceTrend: TrendDirection
}

enum TrendDirection {
    case increasing
    case decreasing
    case stable
}

struct HealthDataExport: Codable {
    let stepCounts: [Int]
    let distances: [Double]
    let heartRates: [Double]
    let falls: [HKCategorySample]
    
    enum CodingKeys: String, CodingKey {
        case stepCounts, distances, heartRates, fallCount
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(stepCounts, forKey: .stepCounts)
        try container.encode(distances, forKey: .distances)
        try container.encode(heartRates, forKey: .heartRates)
        try container.encode(falls.count, forKey: .fallCount)
    }
} 