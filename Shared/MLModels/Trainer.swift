//
//  Traines.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 09.05.22.
//

import Foundation
import CreateML
import CoreML
import Combine
public struct Trainer {
    var mlDataTableProvider: MlDataTableProvider!
    var regressorTable: MLDataTable?
    var coreDataML: CoreDataML!
    var file: Files?
    var model: Models!
    var targetColumnName: String!
    var timeSeriesColumnName: String?
    var regressor: MLRegressor!
    var classifier: MLClassifier!
    var prediction: Predictions!
    init(mlDataTableProvider: MlDataTableProvider, model: Models) {
            self.model = model
            let columnDataModel = ColumnsModel(model: self.model )
            let targetColumn = columnDataModel.timedependantTargetColums.first
            let predictedColumnName = "Predicted: " + (targetColumn?.name)!
            self.mlDataTableProvider = mlDataTableProvider
            self.regressorTable = self.mlDataTableProvider.mlDataTable
            let minorityColumn = regressorTable![targetColumn!.name!]
            let minorityMask = minorityColumn == 0
            let minorityTable = self.regressorTable![minorityMask]
            for _ in 0..<10 {
                regressorTable?.append(contentsOf: minorityTable)
            }
            self.regressorTable!.removeColumn(named: predictedColumnName)
            self.regressorTable!.removeColumn(named: columnDataModel.primaryKeyColumn!.name!)
            self.targetColumnName = self.mlDataTableProvider.orderedColumns.first(where: { $0.istarget == 1})?.name!
            self.timeSeriesColumnName = self.mlDataTableProvider.orderedColumns.first(where: { $0.istimeseries == 1})?.name
            if self.timeSeriesColumnName != nil {
                let timeSeriesColumn = self.regressorTable![timeSeriesColumnName!]
                let seriesEnd = (timeSeriesColumn.ints?.max())!
                let endMask = timeSeriesColumn < seriesEnd
                self.regressorTable = self.regressorTable![endMask]
            }
        }
    init(model: Models, file: Files? = nil) {
        self.model = model
        self.file = file
        coreDataML = CoreDataML(model: model)
        regressorTable = CoreDataML(model: model).mlDataTable
        self.targetColumnName = coreDataML.targetColumns.first?.name
        guard self.targetColumnName != nil else {
            return
        }
        guard regressorTable != nil else {
            return
        }
    }
    public mutating func createModel(regressorName: String) -> Void {
        let columnDataModel = ColumnsModel(model: self.model )
        let targetColumn = columnDataModel.timedependantTargetColums.first
        let predictedColumnName = "Predicted: " + (targetColumn?.name)!
        if self.regressorTable!.columnNames.contains(predictedColumnName) {
            self.regressorTable!.removeColumn(named: predictedColumnName)
        }
        //        this sets aside 20% of each model’s data rows for evaluation, leaving the remaining 80% for training.
        let (regressorEvaluationTable, regressorTrainingTable) = regressorTable!.randomSplit(by: 0.2, seed: 5)
        switch regressorName {
        case "MLLinearRegressor":
            let defaultParams = MLLinearRegressor.ModelParameters(validation: .split(strategy: .automatic), maxIterations: 500, l1Penalty: 0, l2Penalty: 0.001, stepSize: 0.001, convergenceThreshold: 0.001, featureRescaling: true)
            regressor = {
                do {
                    return try MLRegressor.linear(MLLinearRegressor(trainingData: regressorTrainingTable,
                                                                    targetColumn: self.targetColumnName, parameters: defaultParams))
                } catch {
                    fatalError(error.localizedDescription)
                }
            }()
        case "MLDecisionTreeRegressor":
            let defaultParams = MLDecisionTreeRegressor.ModelParameters(validation:.split(strategy: .automatic) , maxDepth: 300, minLossReduction: 0, minChildWeight: 0.01, randomSeed: 42)
            regressor = {
                do {
                    return try MLRegressor.decisionTree(MLDecisionTreeRegressor(trainingData: regressorTrainingTable, targetColumn: self.targetColumnName, parameters: defaultParams))
                } catch {
                    fatalError(error.localizedDescription)
                }
            }()
        case "MLRandomForestRegressor":
            let defaultParams = MLRandomForestRegressor.ModelParameters(validation: .split(strategy: .automatic), maxDepth: 1000, maxIterations: 500, minLossReduction: 0, minChildWeight: 0.01, randomSeed: 42, rowSubsample: 0.8, columnSubsample: 0.8)
            regressor = {
                do {
                    return try MLRegressor.randomForest(MLRandomForestRegressor(trainingData: regressorTrainingTable, targetColumn: self.targetColumnName, parameters: defaultParams))
                } catch {
                    fatalError(error.localizedDescription)
                }
            }()
        case "MLBoostedTreeRegressor":
            //            init(
            //                validationData: MLDataTable? = nil,
            //                maxDepth: Int = 6,
            //                maxIterations: Int = 10,
            //                minLossReduction: Double = 0,
            //                minChildWeight: Double = 0.1,
            //                randomSeed: Int = 42,
            //                stepSize: Double = 0.3,
            //                earlyStoppingRounds: Int? = nil,
            //                rowSubsample: Double = 1.0,
            //                columnSubsample: Double = 1.0
            //            )
            
            let defaultParams = MLBoostedTreeRegressor.ModelParameters(validation: .split(strategy: .automatic) , maxDepth: 1000, maxIterations: 500, minLossReduction: 0, minChildWeight: 0.01, randomSeed: 42, stepSize: 0.1, earlyStoppingRounds: nil, rowSubsample: 1.0, columnSubsample: 1.0)
            regressor =  {
                do {
                    return try MLRegressor.boostedTree(MLBoostedTreeRegressor(trainingData: regressorTrainingTable,
                                                                              targetColumn: targetColumnName, parameters: defaultParams ))
                } catch {
                    fatalError(error.localizedDescription)
                }
            }()
            
        case "MLSupportVectorClassifier":
            let defaultParams = MLSupportVectorClassifier.ModelParameters(maxIterations: 5000, penalty: 1.0, convergenceThreshold: 0.001, featureRescaling: true)
            classifier = {
                do {
                    return try MLClassifier.supportVector(MLSupportVectorClassifier(trainingData: regressorTrainingTable, targetColumn: targetColumnName))
                } catch {
                    fatalError(error.localizedDescription)
                }
            }()
        case "MLBoostedTreeClassifier":
            let defaultParams = MLBoostedTreeClassifier.ModelParameters(validation: .split(strategy: .automatic) , maxDepth: 6, maxIterations: 500, minLossReduction: 0, minChildWeight: 0.1, randomSeed: 42, stepSize: 0.3, earlyStoppingRounds: nil, rowSubsample: 1.0, columnSubsample: 1.0)
            classifier = {
                do {
                    return try MLClassifier.boostedTree((MLBoostedTreeClassifier(trainingData: regressorTrainingTable, targetColumn: targetColumnName, parameters: defaultParams)))
                } catch {
                    fatalError(error.localizedDescription)
                }
            }()
        case "MLRandomForestClassifier":
            let defaultParams = MLRandomForestClassifier.ModelParameters(validation: .split(strategy: .automatic), maxDepth: 100, maxIterations: 300, minLossReduction: 0, minChildWeight: 0.01, randomSeed: 42, rowSubsample: 0.8, columnSubsample: 0.8)
            classifier = {
                do {
                    return try MLClassifier.randomForest(MLRandomForestClassifier(trainingData: regressorTrainingTable, targetColumn: self.targetColumnName, parameters: defaultParams))
                } catch {
                    fatalError(error.localizedDescription)
                }
            }()
        case "MLDecisionTreeClassifier":
            
            let defaultParams = MLDecisionTreeClassifier.ModelParameters(validation:.split(strategy: .automatic) , maxDepth: 300, minLossReduction: 0, minChildWeight: 0.01, randomSeed: 42)
            classifier = {
                do {
                    return try MLClassifier.decisionTree(MLDecisionTreeClassifier(trainingData: regressorTrainingTable, targetColumn: self.targetColumnName, parameters: defaultParams))
                } catch {
                    fatalError(error.localizedDescription)
                }
            }()
        default:
            fatalError()
        }
        if regressor != nil {
            writeMetrics(regressor: regressor, regressorName:  regressorName, regressorEvaluationTable: regressorEvaluationTable)
        }
        if classifier != nil {
            do {
                let classifierMetaData = MLModelMetadata(author: "Steps.IT",
                                                         shortDescription: "Vorhersage des Kündigungsverhaltens von Kunden via Classifier",
                                                         version: "1.0")
                try classifier.write(to: BaseServices.homePath.appendingPathComponent((self.mlDataTableProvider.model?.name!)!, isDirectory: true).appendingPathComponent(regressorName + "_" + self.mlDataTableProvider.prediction!.id!.uuidString + ".mlmodel"),
                                     metadata: classifierMetaData)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
        
    }
    private func doit(regressorTrainingTable: MLDataTable) -> Void {
        let sessionDirectory = URL(fileURLWithPath: "\(NSTemporaryDirectory())churn")
        var subscriptions = [AnyCancellable]()
        let defaultParams = MLBoostedTreeClassifier.ModelParameters(validation: .split(strategy: .automatic) , maxDepth: 1000, maxIterations: 500, minLossReduction: 0, minChildWeight: 0.01, randomSeed: 42, stepSize: 0.1, earlyStoppingRounds: nil, rowSubsample: 1.0, columnSubsample: 1.0)
        let sessionParameters = MLTrainingSessionParameters(reportInterval: 10, checkpointInterval: 10, iterations: 100)
        let job = try! MLBoostedTreeClassifier.train(trainingData: regressorTrainingTable, targetColumn: targetColumnName, parameters: defaultParams, sessionParameters: sessionParameters)
        job.result.sink { result in
            print(result)
        }
    receiveValue: { model in
        try? model.write(to: sessionDirectory)
    }
    .store(in: &subscriptions)
        job.progress.publisher(for: \.fractionCompleted).sink { [weak job] completed in
            guard let job = job, let progress = MLProgress(progress: job.progress) else {
                return
            }
            print("com: \(completed)")
        }
        .store(in: &subscriptions)
        print ("registered subscription count: \(subscriptions.count)")
    }
    private func writeMetrics (regressor: MLRegressor, regressorName: String, regressorEvaluationTable: MLDataTable) -> Void {
        let regressorKPI = Ml_MetricKPI()
        regressorKPI.dictOfMetrics["trainingMetrics.maximumError"]? = regressor.trainingMetrics.maximumError
        regressorKPI.dictOfMetrics["trainingMetrics.rootMeanSquaredError"]? = regressor.trainingMetrics.rootMeanSquaredError
        regressorKPI.dictOfMetrics["validationMetrics.maximumError"]? = regressor.validationMetrics.maximumError
        regressorKPI.dictOfMetrics["validationMetrics.rootMeanSquaredError"]? = regressor.validationMetrics.rootMeanSquaredError
        
        /// Evaluation
        let regressorEvalutation = regressor.evaluation(on: regressorEvaluationTable)
        regressorKPI.dictOfMetrics["evaluationMetrics.maximumError"]? = regressorEvalutation.maximumError
        regressorKPI.dictOfMetrics["evaluationMetrics.rootMeanSquaredError"]? = regressorEvalutation.rootMeanSquaredError
        /// Schreibe in CoreData
        regressorKPI.postMetric(prediction: self.mlDataTableProvider.prediction!, algorithmName: self.mlDataTableProvider.regressorName!)
        let regressorMetadata = MLModelMetadata(author: "Steps.IT",
                                                shortDescription: "Vorhersage des Kündigungsverhaltens von Kunden",
                                                version: "1.0")
        /// Speichern des trainierten Modells auf dem Schreibtisch
        do {
            try regressor.write(to: BaseServices.homePath.appendingPathComponent((self.mlDataTableProvider.model?.name!)!, isDirectory: true).appendingPathComponent(regressorName + "_" + self.mlDataTableProvider.prediction!.id!.uuidString + ".mlmodel"),
                                metadata: regressorMetadata)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
}

