import Foundation
import SwiftUI
import Combine
import CoreML

class MLService: ObservableObject {
    @Published var isTraining: Bool = false
    @Published var trainingProgress: Double = 0.0
    @Published var models: [MLModel] = []
    @Published var activeModels: [MLModel] = []
    @Published var modelMetrics: [ModelMetrics] = []
    @Published var predictions: [Prediction] = []
    @Published var trainingHistory: [TrainingSession] = []
    @Published var modelSettings: MLSettings = MLSettings()
    @Published var isPredicting: Bool = false
    @Published var predictionAccuracy: Double = 0.0
    
    private let mlQueue = DispatchQueue(label: "com.rbc.ml", qos: .userInitiated)
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - ML Model Types
    
    enum ModelType: String, CaseIterable, Identifiable {
        case classification = "Classification"
        case regression = "Regression"
        case clustering = "Clustering"
        case timeSeries = "Time Series"
        case nlp = "Natural Language Processing"
        case computerVision = "Computer Vision"
        case recommendation = "Recommendation"
        case anomalyDetection = "Anomaly Detection"
        case forecasting = "Forecasting"
        case custom = "Custom"
        
        var id: String { return rawValue }
        
        var displayName: String {
            switch self {
            case .classification: return "Classification"
            case .regression: return "Regression"
            case .clustering: return "Clustering"
            case .timeSeries: return "Time Series"
            case .nlp: return "Natural Language Processing"
            case .computerVision: return "Computer Vision"
            case .recommendation: return "Recommendation"
            case .anomalyDetection: return "Anomaly Detection"
            case .forecasting: return "Forecasting"
            case .custom: return "Custom"
            }
        }
        
        var description: String {
            switch self {
            case .classification: return "Classify data into predefined categories"
            case .regression: return "Predict continuous numerical values"
            case .clustering: return "Group similar data points together"
            case .timeSeries: return "Analyze time-based data patterns"
            case .nlp: return "Process and understand natural language"
            case .computerVision: return "Analyze and interpret visual data"
            case .recommendation: return "Provide personalized recommendations"
            case .anomalyDetection: return "Detect unusual patterns or outliers"
            case .forecasting: return "Predict future values based on historical data"
            case .custom: return "Custom machine learning models"
            }
        }
        
        var icon: String {
            switch self {
            case .classification: return "tag"
            case .regression: return "chart.line.uptrend.xyaxis"
            case .clustering: return "circle.grid.3x3"
            case .timeSeries: return "clock"
            case .nlp: return "text.bubble"
            case .computerVision: return "camera"
            case .recommendation: return "star"
            case .anomalyDetection: return "exclamationmark.triangle"
            case .forecasting: return "chart.line.uptrend.xyaxis.circle"
            case .custom: return "gear"
            }
        }
        
        var category: ModelCategory {
            switch self {
            case .classification, .regression, .clustering:
                return .traditional
            case .timeSeries, .forecasting:
                return .timeSeries
            case .nlp:
                return .nlp
            case .computerVision:
                return .computerVision
            case .recommendation:
                return .recommendation
            case .anomalyDetection:
                return .anomalyDetection
            case .custom:
                return .custom
            }
        }
    }
    
    // MARK: - Model Categories
    
    enum ModelCategory: String, CaseIterable {
        case traditional = "Traditional ML"
        case timeSeries = "Time Series"
        case nlp = "Natural Language Processing"
        case computerVision = "Computer Vision"
        case recommendation = "Recommendation Systems"
        case anomalyDetection = "Anomaly Detection"
        case custom = "Custom Models"
        
        var id: String { return rawValue }
        
        var displayName: String {
            switch self {
            case .traditional: return "Traditional ML"
            case .timeSeries: return "Time Series"
            case .nlp: return "Natural Language Processing"
            case .computerVision: return "Computer Vision"
            case .recommendation: return "Recommendation Systems"
            case .anomalyDetection: return "Anomaly Detection"
            case .custom: return "Custom Models"
            }
        }
    }
    
    // MARK: - Model Status
    
    enum ModelStatus: String, CaseIterable {
        case training = "Training"
        case trained = "Trained"
        case active = "Active"
        case inactive = "Inactive"
        case testing = "Testing"
        case failed = "Failed"
        case deprecated = "Deprecated"
        
        var id: String { return rawValue }
        
        var color: Color {
            switch self {
            case .training: return .yellow
            case .trained: return .green
            case .active: return .blue
            case .inactive: return .gray
            case .testing: return .orange
            case .failed: return .red
            case .deprecated: return .purple
            }
        }
        
        var icon: String {
            switch self {
            case .training: return "arrow.triangle.2.circlepath"
            case .trained: return "checkmark.circle"
            case .active: return "play.circle"
            case .inactive: return "pause.circle"
            case .testing: return "magnifyingglass"
            case .failed: return "xmark.circle"
            case .deprecated: return "clock"
            }
        }
    }
    
    // MARK: - Training Algorithms
    
    enum TrainingAlgorithm: String, CaseIterable {
        case randomForest = "Random Forest"
        case svm = "Support Vector Machine"
        case neuralNetwork = "Neural Network"
        case linearRegression = "Linear Regression"
        case logisticRegression = "Logistic Regression"
        case decisionTree = "Decision Tree"
        case gradientBoosting = "Gradient Boosting"
        case kMeans = "K-Means"
        case lstm = "LSTM"
        case cnn = "Convolutional Neural Network"
        case transformer = "Transformer"
        case autoencoder = "Autoencoder"
        
        var id: String { return rawValue }
        
        var supportedTypes: [ModelType] {
            switch self {
            case .randomForest:
                return [.classification, .regression]
            case .svm:
                return [.classification, .regression]
            case .neuralNetwork:
                return [.classification, .regression, .timeSeries, .nlp, .computerVision]
            case .linearRegression:
                return [.regression]
            case .logisticRegression:
                return [.classification]
            case .decisionTree:
                return [.classification, .regression]
            case .gradientBoosting:
                return [.classification, .regression]
            case .kMeans:
                return [.clustering]
            case .lstm:
                return [.timeSeries, .nlp]
            case .cnn:
                return [.computerVision, .timeSeries]
            case .transformer:
                return [.nlp, .timeSeries]
            case .autoencoder:
                return [.anomalyDetection, .clustering]
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        setupMLService()
        loadMLSettings()
        loadModels()
        setupModelMonitoring()
    }
    
    private func setupMLService() {
        // Initialize ML service
        // Set up default settings
    }
    
    private func loadMLSettings() {
        let defaults = UserDefaults.standard
        
        if let data = defaults.data(forKey: "ml_settings"),
           let settings = try? JSONDecoder().decode(MLSettings.self, from: data) {
            modelSettings = settings
        }
    }
    
    private func saveMLSettings() {
        let defaults = UserDefaults.standard
        
        if let data = try? JSONEncoder().encode(modelSettings) {
            defaults.set(data, forKey: "ml_settings")
        }
    }
    
    private func loadModels() {
        let defaults = UserDefaults.standard
        
        if let data = defaults.data(forKey: "ml_models"),
           let loadedModels = try? JSONDecoder().decode([MLModel].self, from: data) {
            models = loadedModels
            activeModels = models.filter { $0.status == .active }
        }
        
        if let data = defaults.data(forKey: "training_history"),
           let history = try? JSONDecoder().decode([TrainingSession].self, from: data) {
            trainingHistory = history
        }
    }
    
    private func saveModels() {
        let defaults = UserDefaults.standard
        
        if let data = try? JSONEncoder().encode(models) {
            defaults.set(data, forKey: "ml_models")
        }
        
        if let data = try? JSONEncoder().encode(trainingHistory) {
            defaults.set(data, forKey: "training_history")
        }
    }
    
    private func setupModelMonitoring() {
        // Set up model performance monitoring
        Timer.scheduledTimer(withTimeInterval: 3600.0, repeats: true) { [weak self] _ in
            self?.monitorModelPerformance()
        }
    }
    
    private func monitorModelPerformance() {
        for model in activeModels {
            let metrics = evaluateModelPerformance(model)
            
            if let index = modelMetrics.firstIndex(where: { $0.modelId == model.id }) {
                modelMetrics[index] = metrics
            } else {
                modelMetrics.append(metrics)
            }
        }
        
        // Keep only recent metrics (last 100)
        if modelMetrics.count > 100 {
            modelMetrics = Array(modelMetrics.suffix(100))
        }
    }
    
    private func evaluateModelPerformance(_ model: MLModel) -> ModelMetrics {
        // Simulate model performance evaluation
        let accuracy = Double.random(in: 0.7...0.95)
        let precision = Double.random(in: 0.7...0.95)
        let recall = Double.random(in: 0.7...0.95)
        let f1Score = 2 * (precision * recall) / (precision + recall)
        
        return ModelMetrics(
            modelId: model.id,
            modelName: model.name,
            accuracy: accuracy,
            precision: precision,
            recall: recall,
            f1Score: f1Score,
            timestamp: Date(),
            predictionsCount: Int.random(in: 100...1000),
            errorRate: 1.0 - accuracy
        )
    }
    
    // MARK: - Model Training
    
    func trainModel(_ modelConfig: ModelConfiguration, trainingData: [TrainingData]) {
        isTraining = true
        trainingProgress = 0.0
        
        mlQueue.async {
            let trainingResult = self.performTraining(modelConfig, trainingData: trainingData)
            
            DispatchQueue.main.async {
                self.processTrainingResult(trainingResult)
            }
        }
    }
    
    private func performTraining(_ config: ModelConfiguration, trainingData: [TrainingData]) -> TrainingResult {
        let startTime = Date()
        var progress: Double = 0.0
        var success = true
        var errorMessage: String?
        
        // Simulate training process
        let totalEpochs = 100
        
        for epoch in 1...totalEpochs {
            // Simulate training epoch
            Thread.sleep(forTimeInterval: 0.1)
            
            progress = Double(epoch) / Double(totalEpochs)
            
            DispatchQueue.main.async {
                self.trainingProgress = progress
            }
            
            // Simulate training failure (10% chance)
            if Bool.random() && epoch == totalEpochs / 2 {
                success = false
                errorMessage = "Training failed due to convergence issues"
                break
            }
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        return TrainingResult(
            modelId: UUID().uuidString,
            success: success,
            duration: duration,
            accuracy: success ? Double.random(in: 0.8...0.95) : 0.0,
            errorMessage: errorMessage,
            completedAt: Date()
        )
    }
    
    private func processTrainingResult(_ result: TrainingResult) {
        isTraining = false
        trainingProgress = 1.0
        
        if result.success {
            let model = MLModel(
                id: result.modelId,
                name: "Trained Model \(models.count + 1)",
                type: .classification,
                algorithm: .neuralNetwork,
                status: .trained,
                accuracy: result.accuracy,
                createdAt: result.completedAt,
                lastTrainedAt: result.completedAt,
                version: "1.0",
                description: "Automatically trained model",
                parameters: [:],
                isActive: false
            )
            
            models.append(model)
            
            // Create training session record
            let session = TrainingSession(
                id: UUID().uuidString,
                modelId: model.id,
                startTime: result.completedAt.addingTimeInterval(-result.duration),
                endTime: result.completedAt,
                duration: result.duration,
                success: true,
                accuracy: result.accuracy,
                algorithm: .neuralNetwork,
                trainingDataSize: 1000,
                validationDataSize: 200
            )
            
            trainingHistory.append(session)
        }
        
        saveModels()
    }
    
    // MARK: - Model Prediction
    
    func predict(with modelId: String, inputData: [String: Any]) -> Prediction? {
        guard let model = models.first(where: { $0.id == modelId }) else { return nil }
        
        isPredicting = true
        
        let prediction = performPrediction(model: model, inputData: inputData)
        
        predictions.append(prediction)
        
        // Keep only recent predictions (last 100)
        if predictions.count > 100 {
            predictions = Array(predictions.suffix(100))
        }
        
        isPredicting = false
        
        return prediction
    }
    
    private func performPrediction(model: MLModel, inputData: [String: Any]) -> Prediction {
        // Simulate prediction
        Thread.sleep(forTimeInterval: 0.5)
        
        let confidence = Double.random(in: 0.7...0.95)
        let result = generatePredictionResult(model: model, inputData: inputData)
        
        return Prediction(
            id: UUID().uuidString,
            modelId: model.id,
            modelName: model.name,
            inputData: inputData,
            result: result,
            confidence: confidence,
            timestamp: Date(),
            processingTime: 0.5
        )
    }
    
    private func generatePredictionResult(model: MLModel, inputData: [String: Any]) -> [String: Any] {
        switch model.type {
        case .classification:
            return [
                "class": ["A", "B", "C"].randomElement() ?? "A",
                "probabilities": [
                    "A": Double.random(in: 0.1...0.8),
                    "B": Double.random(in: 0.1...0.8),
                    "C": Double.random(in: 0.1...0.8)
                ]
            ]
        case .regression:
            return [
                "value": Double.random(in: 0...100),
                "range": [Double.random(in: 0...50), Double.random(in: 50...100)]
            ]
        case .clustering:
            return [
                "cluster": Int.random(in: 0...4),
                "distance": Double.random(in: 0.1...1.0)
            ]
        case .timeSeries:
            return [
                "next_value": Double.random(in: 0...100),
                "trend": ["up", "down", "stable"].randomElement() ?? "stable",
                "confidence_interval": [
                    Double.random(in: 0...100),
                    Double.random(in: 0...100)
                ]
            ]
        case .nlp:
            return [
                "sentiment": ["positive", "negative", "neutral"].randomElement() ?? "neutral",
                "entities": ["entity1", "entity2"],
                "intent": "classify"
            ]
        case .computerVision:
            return [
                "class": ["cat", "dog", "bird"].randomElement() ?? "cat",
                "bounding_box": [0.1, 0.1, 0.8, 0.8],
                "confidence": Double.random(in: 0.7...0.95)
            ]
        case .recommendation:
            return [
                "recommendations": [
                    ["item": "item1", "score": Double.random(in: 0.7...0.95)],
                    ["item": "item2", "score": Double.random(in: 0.7...0.95)],
                    ["item": "item3", "score": Double.random(in: 0.7...0.95)]
                ]
            ]
        case .anomalyDetection:
            return [
                "is_anomaly": Bool.random(),
                "anomaly_score": Double.random(in: 0...1),
                "threshold": 0.5
            ]
        case .forecasting:
            return [
                "forecast": Array(0..<10).map { _ in Double.random(in: 0...100) },
                "confidence_intervals": Array(0..<10).map { _ in [Double.random(in: 0...50), Double.random(in: 50...100)] }
            ]
        case .custom:
            return [
                "custom_result": "Custom prediction result",
                "metadata": ["key": "value"]
            ]
        }
    }
    
    // MARK: - Model Management
    
    func activateModel(_ modelId: String) {
        if let index = models.firstIndex(where: { $0.id == modelId }) {
            models[index].status = .active
            models[index].isActive = true
            models[index].activatedAt = Date()
            
            activeModels = models.filter { $0.status == .active }
            saveModels()
        }
    }
    
    func deactivateModel(_ modelId: String) {
        if let index = models.firstIndex(where: { $0.id == modelId }) {
            models[index].status = .inactive
            models[index].isActive = false
            
            activeModels = models.filter { $0.status == .active }
            saveModels()
        }
    }
    
    func deleteModel(_ modelId: String) {
        models.removeAll { $0.id == modelId }
        activeModels = models.filter { $0.status == .active }
        modelMetrics.removeAll { $0.modelId == modelId }
        saveModels()
    }
    
    func retrainModel(_ modelId: String, trainingData: [TrainingData]) {
        guard let model = models.first(where: { $0.id == modelId }) else { return }
        
        let config = ModelConfiguration(
            name: model.name,
            type: model.type,
            algorithm: model.algorithm,
            parameters: model.parameters
        )
        
        trainModel(config, trainingData: trainingData)
    }
    
    // MARK: - Batch Predictions
    
    func batchPredict(modelId: String, inputDataBatch: [[String: Any]]) -> [Prediction] {
        guard let model = models.first(where: { $0.id == modelId }) else { return [] }
        
        isPredicting = true
        
        var batchResults: [Prediction] = []
        
        for inputData in inputDataBatch {
            let prediction = performPrediction(model: model, inputData: inputData)
            batchResults.append(prediction)
        }
        
        predictions.append(contentsOf: batchResults)
        
        // Keep only recent predictions (last 100)
        if predictions.count > 100 {
            predictions = Array(predictions.suffix(100))
        }
        
        isPredicting = false
        
        return batchResults
    }
    
    // MARK: - Model Evaluation
    
    func evaluateModel(_ modelId: String, testData: [TrainingData]) -> ModelEvaluation {
        guard let model = models.first(where: { $0.id == modelId }) else {
            return ModelEvaluation(
                modelId: modelId,
                accuracy: 0.0,
                precision: 0.0,
                recall: 0.0,
                f1Score: 0.0,
                confusionMatrix: [:],
                timestamp: Date()
            )
        }
        
        // Simulate model evaluation
        let accuracy = Double.random(in: 0.7...0.95)
        let precision = Double.random(in: 0.7...0.95)
        let recall = Double.random(in: 0.7...0.95)
        let f1Score = 2 * (precision * recall) / (precision + recall)
        
        let confusionMatrix: [String: [String: Int]] = [
            "A": ["A": Int.random(in: 80...95), "B": Int.random(in: 0...10), "C": Int.random(in: 0...10)],
            "B": ["A": Int.random(in: 0...10), "B": Int.random(in: 80...95), "C": Int.random(in: 0...10)],
            "C": ["A": Int.random(in: 0...10), "B": Int.random(in: 0...10), "C": Int.random(in: 80...95)]
        ]
        
        return ModelEvaluation(
            modelId: modelId,
            accuracy: accuracy,
            precision: precision,
            recall: recall,
            f1Score: f1Score,
            confusionMatrix: confusionMatrix,
            timestamp: Date()
        )
    }
    
    // MARK: - Public Interface
    
    func getModels(for type: ModelType) -> [MLModel] {
        return models.filter { $0.type == type }
    }
    
    func getModels(for algorithm: TrainingAlgorithm) -> [MLModel] {
        return models.filter { $0.algorithm == algorithm }
    }
    
    func getModelMetrics(_ modelId: String) -> ModelMetrics? {
        return modelMetrics.first { $0.modelId == modelId }
    }
    
    func getTrainingHistory(_ modelId: String) -> [TrainingSession] {
        return trainingHistory.filter { $0.modelId == modelId }
    }
    
    func getPredictions(_ modelId: String) -> [Prediction] {
        return predictions.filter { $0.modelId == modelId }
    }
    
    func getModelReport() -> ModelReport {
        let totalModels = models.count
        let activeModels = activeModels.count
        let trainingSessions = trainingHistory.count
        let successfulTrainings = trainingHistory.filter { $0.success }.count
        let totalPredictions = predictions.count
        let averageAccuracy = models.isEmpty ? 0 : models.map { $0.accuracy }.reduce(0, +) / Double(totalModels)
        
        return ModelReport(
            totalModels: totalModels,
            activeModels: activeModels,
            trainingSessions: trainingSessions,
            successfulTrainings: successfulTrainings,
            totalPredictions: totalPredictions,
            averageAccuracy: averageAccuracy,
            modelTypes: ModelType.allCases.map { type in
                ModelTypeReport(
                    type: type,
                    count: models.filter { $0.type == type }.count,
                    averageAccuracy: models.filter { $0.type == type }.isEmpty ? 0 : models.filter { $0.type == type }.map { $0.accuracy }.reduce(0, +) / Double(models.filter { $0.type == type }.count)
                )
            },
            generatedAt: Date()
        )
    }
    
    func exportModel(_ modelId: String) -> ModelExport? {
        guard let model = models.first(where: { $0.id == modelId }) else { return nil }
        
        let metrics = getModelMetrics(modelId)
        let history = getTrainingHistory(modelId)
        let predictions = getPredictions(modelId)
        
        return ModelExport(
            model: model,
            metrics: metrics,
            trainingHistory: history,
            predictions: predictions,
            exportedAt: Date()
        )
    }
    
    func importModel(_ export: ModelExport) {
        var importedModel = export.model
        importedModel.id = UUID().uuidString
        importedModel.createdAt = Date()
        importedModel.status = .trained
        importedModel.isActive = false
        
        models.append(importedModel)
        
        if let metrics = export.metrics {
            var importedMetrics = metrics
            importedMetrics.modelId = importedModel.id
            modelMetrics.append(importedMetrics)
        }
        
        saveModels()
    }
    
    deinit {
        // Clean up resources
    }
}

// MARK: - Data Structures

struct MLModel: Identifiable, Codable {
    let id: String
    var name: String
    let type: MLService.ModelType
    let algorithm: MLService.TrainingAlgorithm
    var status: MLService.ModelStatus
    var accuracy: Double
    let createdAt: Date
    var lastTrainedAt: Date?
    var activatedAt: Date?
    var version: String
    var description: String
    var parameters: [String: Any]
    var isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, algorithm, status, accuracy
        case createdAt, lastTrainedAt, activatedAt, version, description
        case parameters, isActive
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(MLService.ModelType.self, forKey: .type)
        algorithm = try container.decode(MLService.TrainingAlgorithm.self, forKey: .algorithm)
        status = try container.decode(MLService.ModelStatus.self, forKey: .status)
        accuracy = try container.decode(Double.self, forKey: .accuracy)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastTrainedAt = try container.decodeIfPresent(Date.self, forKey: .lastTrainedAt)
        activatedAt = try container.decodeIfPresent(Date.self, forKey: .activatedAt)
        version = try container.decode(String.self, forKey: .version)
        description = try container.decode(String.self, forKey: .description)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        
        // Decode parameters as JSON
        if let data = try? container.decode(Data.self, forKey: .parameters),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            parameters = dict
        } else {
            parameters = [:]
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(algorithm, forKey: .algorithm)
        try container.encode(status, forKey: .status)
        try container.encode(accuracy, forKey: .accuracy)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(lastTrainedAt, forKey: .lastTrainedAt)
        try container.encodeIfPresent(activatedAt, forKey: .activatedAt)
        try container.encode(version, forKey: .version)
        try container.encode(description, forKey: .description)
        try container.encode(isActive, forKey: .isActive)
        
        // Encode parameters as JSON
        if let data = try? JSONSerialization.data(withJSONObject: parameters) {
            try container.encode(data, forKey: .parameters)
        }
    }
}

struct ModelConfiguration {
    let name: String
    let type: MLService.ModelType
    let algorithm: MLService.TrainingAlgorithm
    let parameters: [String: Any]
}

struct TrainingData {
    let features: [String: Any]
    let label: String?
    let timestamp: Date
}

struct TrainingResult {
    let modelId: String
    let success: Bool
    let duration: TimeInterval
    let accuracy: Double
    let errorMessage: String?
    let completedAt: Date
}

struct TrainingSession: Identifiable, Codable {
    let id: String
    let modelId: String
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let success: Bool
    let accuracy: Double
    let algorithm: MLService.TrainingAlgorithm
    let trainingDataSize: Int
    let validationDataSize: Int
}

struct Prediction: Identifiable, Codable {
    let id: String
    let modelId: String
    let modelName: String
    let inputData: [String: Any]
    let result: [String: Any]
    let confidence: Double
    let timestamp: Date
    let processingTime: TimeInterval
    
    enum CodingKeys: String, CodingKey {
        case id, modelId, modelName, result, confidence
        case timestamp, processingTime, inputData
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        modelId = try container.decode(String.self, forKey: .modelId)
        modelName = try container.decode(String.self, forKey: .modelName)
        result = try container.decode([String: Any].self, forKey: .result)
        confidence = try container.decode(Double.self, forKey: .confidence)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        processingTime = try container.decode(TimeInterval.self, forKey: .processingTime)
        
        // Decode inputData as JSON
        if let data = try? container.decode(Data.self, forKey: .inputData),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            inputData = dict
        } else {
            inputData = [:]
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(modelId, forKey: .modelId)
        try container.encode(modelName, forKey: .modelName)
        try container.encode(result, forKey: .result)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(processingTime, forKey: .processingTime)
        
        // Encode inputData as JSON
        if let data = try? JSONSerialization.data(withJSONObject: inputData) {
            try container.encode(data, forKey: .inputData)
        }
    }
}

struct ModelMetrics: Identifiable, Codable {
    let modelId: String
    let modelName: String
    let accuracy: Double
    let precision: Double
    let recall: Double
    let f1Score: Double
    let timestamp: Date
    let predictionsCount: Int
    let errorRate: Double
    
    var id: String { return modelId }
}

struct ModelEvaluation {
    let modelId: String
    let accuracy: Double
    let precision: Double
    let recall: Double
    let f1Score: Double
    let confusionMatrix: [String: [String: Int]]
    let timestamp: Date
}

struct MLSettings: Codable {
    var enableAutoTraining: Bool = true
    var enableModelMonitoring: Bool = true
    var maxConcurrentTrainings: Int = 2
    var defaultTrainingTimeout: TimeInterval = 3600.0 // 1 hour
    var enableModelVersioning: Bool = true
    var enableModelBackup: Bool = true
    var maxModelHistory: Int = 10
    var enablePredictionLogging: Bool = true
    var maxPredictionHistory: Int = 1000
    var enablePerformanceMonitoring: Bool = true
    var performanceCheckInterval: TimeInterval = 3600.0 // 1 hour
}

struct ModelReport {
    let totalModels: Int
    let activeModels: Int
    let trainingSessions: Int
    let successfulTrainings: Int
    let totalPredictions: Int
    let averageAccuracy: Double
    let modelTypes: [ModelTypeReport]
    let generatedAt: Date
}

struct ModelTypeReport {
    let type: MLService.ModelType
    let count: Int
    let averageAccuracy: Double
}

struct ModelExport: Codable {
    let model: MLModel
    let metrics: ModelMetrics?
    let trainingHistory: [TrainingSession]
    let predictions: [Prediction]
    let exportedAt: Date
}
