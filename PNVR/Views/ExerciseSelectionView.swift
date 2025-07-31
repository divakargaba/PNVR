import SwiftUI

struct ExerciseSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var rehabilitationViewModel: RehabilitationViewModel
    @State private var selectedExerciseType: ExerciseType = .staticBalance
    @State private var selectedDifficulty: ExerciseDifficulty = .beginner
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Exercise Type Selection
                exerciseTypeSection
                
                // Difficulty Selection
                difficultySection
                
                // Exercise Description
                exerciseDescriptionSection
                
                // Start Button
                startButton
                
                Spacer()
            }
            .padding()
            .navigationTitle("Select Exercise")
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
    
    // MARK: - Exercise Type Section
    private var exerciseTypeSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Exercise Type")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                ForEach(ExerciseType.allCases, id: \.self) { exerciseType in
                    ExerciseTypeCard(
                        exerciseType: exerciseType,
                        isSelected: selectedExerciseType == exerciseType
                    ) {
                        selectedExerciseType = exerciseType
                    }
                }
            }
        }
    }
    
    // MARK: - Difficulty Section
    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Difficulty Level")
                .font(.headline)
            
            VStack(spacing: 10) {
                ForEach(ExerciseDifficulty.allCases, id: \.self) { difficulty in
                    DifficultyCard(
                        difficulty: difficulty,
                        isSelected: selectedDifficulty == difficulty
                    ) {
                        selectedDifficulty = difficulty
                    }
                }
            }
        }
    }
    
    // MARK: - Exercise Description Section
    private var exerciseDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Exercise Description")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 10) {
                Text(exerciseDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Text("Estimated Duration: \(estimatedDuration)")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                
                Text("Focus Areas: \(focusAreas)")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Start Button
    private var startButton: some View {
        Button("Start Exercise") {
            rehabilitationViewModel.startSession(
                exerciseType: selectedExerciseType,
                difficulty: selectedDifficulty
            )
            dismiss()
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Computed Properties
    private var exerciseDescription: String {
        switch selectedExerciseType {
        case .staticBalance:
            return "Stand in a comfortable position and maintain your balance. Focus on keeping your center of gravity stable while the VR environment provides gentle challenges."
        case .dynamicBalance:
            return "Move your body while maintaining balance. The VR environment will present dynamic obstacles and challenges that require you to shift your weight and adjust your stance."
        case .gaitTraining:
            return "Practice walking patterns in a controlled VR environment. Focus on step length, cadence, and symmetry while navigating through virtual pathways."
        case .obstacleCourse:
            return "Navigate through a series of virtual obstacles that challenge your balance, coordination, and spatial awareness. This exercise combines multiple skills."
        case .dualTask:
            return "Perform balance exercises while simultaneously completing cognitive tasks. This improves your ability to maintain stability during complex activities."
        case .vestibularTraining:
            return "Engage in exercises that challenge your vestibular system through visual and movement stimuli. This helps improve your sense of balance and spatial orientation."
        }
    }
    
    private var estimatedDuration: String {
        switch selectedDifficulty {
        case .beginner: return "10-15 minutes"
        case .intermediate: return "15-20 minutes"
        case .advanced: return "20-25 minutes"
        case .expert: return "25-30 minutes"
        }
    }
    
    private var focusAreas: String {
        switch selectedExerciseType {
        case .staticBalance:
            return "Core stability, postural control, weight distribution"
        case .dynamicBalance:
            return "Weight shifting, movement coordination, reactive balance"
        case .gaitTraining:
            return "Step symmetry, walking speed, stride length"
        case .obstacleCourse:
            return "Spatial awareness, coordination, multi-task balance"
        case .dualTask:
            return "Cognitive-motor integration, divided attention"
        case .vestibularTraining:
            return "Vestibular system, visual-vestibular integration"
        }
    }
}

// MARK: - Exercise Type Card
struct ExerciseTypeCard: View {
    let exerciseType: ExerciseType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: exerciseType.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(exerciseType.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Difficulty Card
struct DifficultyCard: View {
    let difficulty: ExerciseDifficulty
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(difficulty.rawValue)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(difficultyDescription)
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
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var difficultyDescription: String {
        switch difficulty {
        case .beginner:
            return "Basic exercises with support"
        case .intermediate:
            return "Moderate challenges"
        case .advanced:
            return "Complex movements"
        case .expert:
            return "High-level challenges"
        }
    }
}

#Preview {
    ExerciseSelectionView()
        .environmentObject(RehabilitationViewModel())
} 