# PNVR - Peripheral Neuropathy VR Rehabilitation

## Overview

PNVR is a comprehensive iOS application designed for VR-based rehabilitation and gait training for individuals with peripheral neuropathy. The app combines motion tracking, machine learning, and VR integration to provide personalized rehabilitation exercises that improve balance, stability, and walking patterns.

## Key Features

### 🏥 Rehabilitation Features
- **Gait Training**: Real-time balance and walking exercises
- **Stability Exercises**: Dynamic balance challenges with adjustable difficulty
- **Fall Risk Assessment**: Comprehensive metrics to evaluate stability
- **Real-time ML Integration**: Machine learning model adjusts exercise difficulty based on performance

### 🥽 VR Integration
- **Foot Tracking**: Real-time foot movement analysis
- **Torso Tracking**: Body position and balance monitoring
- **Motion Sensors**: Integration with VR motion controllers
- **Haptic Feedback**: Tactile feedback for enhanced rehabilitation

### 📊 Metrics & Analytics
- **Balance Metrics**: Center of pressure, sway analysis
- **Gait Analysis**: Step length, cadence, symmetry
- **Stability Scores**: Real-time stability assessment
- **Progress Tracking**: Long-term rehabilitation progress
- **Fall Risk Index**: Predictive fall risk assessment

## Technical Architecture

### App Structure
```
PNVR/
├── PNVRApp.swift              # Main app entry point
├── ContentView.swift          # Main tab navigation
├── Views/                     # UI Components
│   ├── RehabilitationView.swift
│   ├── MetricsView.swift
│   ├── VRIntegrationView.swift
│   ├── ExerciseSelectionView.swift
│   └── SessionSummaryView.swift
├── ViewModels/               # Business Logic
│   └── RehabilitationViewModel.swift
├── Models/                   # Data Models
│   └── MetricsModel.swift
├── Services/                 # External Integrations
│   ├── VRService.swift
│   ├── MLService.swift
│   └── HealthKitService.swift
└── Assets.xcassets/         # App Resources
```

### Core Components

#### 1. RehabilitationViewModel
- Manages session state and motion tracking
- Processes real-time balance and gait metrics
- Integrates with ML service for predictions
- Handles VR service communication

#### 2. VRService
- Manages VR device connections
- Processes motion data for VR tracking
- Provides haptic and visual feedback
- Handles VR device calibration

#### 3. MLService
- Generates exercise recommendations
- Adjusts difficulty based on performance
- Predicts fall risk and stability scores
- Maintains training data for model improvement

#### 4. HealthKitService
- Integrates with HealthKit for data storage
- Tracks rehabilitation progress over time
- Provides HIPAA-compliant data handling
- Analyzes health trends and patterns

## Data Models

### BalanceMetrics
```swift
struct BalanceMetrics {
    let centerOfPressure: CGPoint
    let swayArea: Double
    let swayVelocity: Double
    let stabilityScore: Double
    let fallRiskIndex: Double
}
```

### GaitMetrics
```swift
struct GaitMetrics {
    let stepLength: Double
    let stepTime: Double
    let cadence: Double
    let gaitSymmetry: Double
    let strideLength: Double
    let walkingSpeed: Double
}
```

### VRTrackingData
```swift
struct VRTrackingData {
    let footPosition: CGPoint
    let torsoPosition: CGPoint
    let footVelocity: CGVector
    let torsoVelocity: CGVector
    let balanceOffset: Double
}
```

## Exercise Types

### 1. Static Balance
- **Purpose**: Improve postural control and core stability
- **Description**: Stand in a comfortable position and maintain balance
- **Focus**: Center of pressure control, weight distribution

### 2. Dynamic Balance
- **Purpose**: Enhance reactive balance and movement coordination
- **Description**: Move body while maintaining balance through obstacles
- **Focus**: Weight shifting, movement coordination

### 3. Gait Training
- **Purpose**: Improve walking patterns and symmetry
- **Description**: Practice walking in controlled VR environment
- **Focus**: Step length, cadence, gait symmetry

### 4. Obstacle Course
- **Purpose**: Challenge spatial awareness and coordination
- **Description**: Navigate through virtual obstacles
- **Focus**: Multi-task balance, spatial awareness

### 5. Dual Task
- **Purpose**: Improve cognitive-motor integration
- **Description**: Balance exercises with cognitive tasks
- **Focus**: Divided attention, complex movements

### 6. Vestibular Training
- **Purpose**: Enhance vestibular system function
- **Description**: Visual and movement stimuli challenges
- **Focus**: Vestibular system, spatial orientation

## Difficulty Levels

### Beginner
- Basic exercises with support
- Longer duration, simpler movements
- Focus on safety and comfort

### Intermediate
- Moderate challenges
- Balanced difficulty progression
- Introduction of complexity

### Advanced
- Complex movements
- Shorter duration, higher intensity
- Multi-component exercises

### Expert
- High-level challenges
- Maximum difficulty settings
- Professional-level exercises

## Metrics & Analytics

### Real-time Metrics
- **Stability Score**: 0-100 scale of balance performance
- **Fall Risk Index**: Predictive fall risk assessment
- **Sway Area**: Postural sway measurement
- **Sway Velocity**: Movement speed analysis
- **Gait Symmetry**: Walking pattern balance
- **Walking Speed**: Movement velocity tracking

### Progress Tracking
- **Session History**: Complete exercise session records
- **Trend Analysis**: Performance improvement over time
- **Fall Risk Trends**: Risk assessment progression
- **Improvement Rates**: Quantified progress metrics

## VR Integration

### Supported Devices
- Meta Quest 3
- HTC Vive
- Valve Index
- Oculus Rift

### Tracking Features
- **Foot Position**: Real-time foot movement tracking
- **Torso Position**: Body position monitoring
- **Velocity Analysis**: Movement speed calculations
- **Balance Offset**: Postural deviation measurement

### Feedback Systems
- **Haptic Feedback**: Tactile response for guidance
- **Visual Cues**: On-screen instructions and feedback
- **Audio Feedback**: Voice guidance and alerts
- **Real-time Adjustments**: Dynamic difficulty modification

## Machine Learning Features

### Prediction Models
- **Exercise Recommendations**: Next best exercise selection
- **Difficulty Adjustment**: Adaptive difficulty based on performance
- **Risk Assessment**: Fall risk prediction and analysis
- **Progress Forecasting**: Long-term improvement predictions

### Model Training
- **Continuous Learning**: Real-time model updates
- **Performance Data**: Session-based training data
- **Personalization**: User-specific model adaptation
- **Validation**: Accuracy and confidence scoring

## HealthKit Integration

### Data Types
- **Step Count**: Walking activity tracking
- **Distance**: Walking distance measurement
- **Heart Rate**: Cardiovascular monitoring
- **Fall Data**: Fall event recording
- **Walking Speed**: Movement velocity
- **Step Length**: Gait parameter tracking

### Privacy & Security
- **HIPAA Compliance**: Healthcare data protection
- **Local Storage**: Encrypted local data storage
- **User Consent**: Explicit permission management
- **Data Export**: Secure data export capabilities

## Installation & Setup

### Requirements
- iOS 15.0 or later
- iPhone with motion sensors
- VR headset (optional for full experience)
- HealthKit permissions

### Setup Process
1. Install the app from App Store
2. Grant motion sensor permissions
3. Configure HealthKit access
4. Calibrate VR devices (if applicable)
5. Complete initial assessment

### VR Setup
1. Connect VR headset to device
2. Calibrate motion controllers
3. Configure tracking sensitivity
4. Test haptic feedback
5. Begin rehabilitation session

## Usage Guide

### Starting a Session
1. Open the PNVR app
2. Navigate to Rehabilitation tab
3. Select "Start New Session"
4. Choose exercise type and difficulty
5. Follow on-screen instructions

### During Exercise
- Maintain proper posture
- Follow VR guidance cues
- Stay within safe movement range
- Monitor real-time metrics
- Complete full session duration

### Session Completion
- Review session summary
- Check performance metrics
- Note ML recommendations
- Plan next session
- Track long-term progress

## Safety Guidelines

### Pre-Exercise
- Consult healthcare provider
- Ensure safe environment
- Remove obstacles
- Have support available if needed

### During Exercise
- Stop if experiencing pain
- Maintain proper form
- Stay within comfort zone
- Use support if necessary

### Post-Exercise
- Cool down properly
- Monitor for adverse effects
- Report any issues
- Follow healthcare recommendations

## Troubleshooting

### Common Issues

#### Motion Tracking Problems
- Ensure device is held properly
- Check motion sensor permissions
- Restart app if needed
- Calibrate sensors

#### VR Connection Issues
- Check device compatibility
- Verify Bluetooth connections
- Restart VR devices
- Update firmware if needed

#### HealthKit Sync Problems
- Verify HealthKit permissions
- Check internet connection
- Restart device if needed
- Contact support if persistent

### Performance Optimization
- Close background apps
- Ensure adequate battery
- Maintain stable internet
- Regular app updates

## Privacy & Data Protection

### Data Collection
- Motion sensor data
- Exercise performance metrics
- HealthKit integration data
- VR tracking information

### Data Usage
- Personalized exercise recommendations
- Progress tracking and analysis
- ML model improvement
- Healthcare provider sharing

### Data Protection
- Local encryption
- HIPAA compliance
- User consent management
- Secure data transmission

## Support & Resources

### Technical Support
- In-app help system
- User documentation
- Video tutorials
- Contact support team

### Healthcare Integration
- Provider dashboard access
- Progress report generation
- Data export capabilities
- Telemedicine integration

### Community Resources
- User forums
- Success stories
- Expert advice
- Research updates

## Future Enhancements

### Planned Features
- Advanced VR environments
- Multi-user sessions
- Telemedicine integration
- Wearable device support
- Advanced ML models
- Social features

### Research Integration
- Clinical trial support
- Research data collection
- Academic partnerships
- Evidence-based updates

## Contributing

### Development
- Swift 5.0+
- SwiftUI framework
- Core Motion integration
- HealthKit integration
- VR device APIs

### Testing
- Unit tests for core functionality
- Integration tests for services
- UI tests for user flows
- Performance testing
- Accessibility testing

### Documentation
- Code documentation
- API documentation
- User guides
- Developer guides

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

For support, questions, or contributions:
- Email: support@pnvr.app
- Website: https://pnvr.app
- Documentation: https://docs.pnvr.app 