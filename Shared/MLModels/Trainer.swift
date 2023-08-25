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
import PythonKit

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
    var pythonInteractor: PythonInteractor!
    var modelContextPath: URL!
    var mlDataTableProviderContext: SimulationController.MlDataTableProviderContext
    init(mlDataProviderContext: SimulationController.MlDataTableProviderContext) {
        self.mlDataTableProviderContext = mlDataProviderContext
        self.model = mlDataProviderContext.model
        self.prediction = mlDataProviderContext.mlDataTableProvider.prediction
        let columnDataModel = ColumnsModel(model: self.model )
        let targetColumn = columnDataModel.timedependantTargetColums.first
        let predictedColumnName = "Predicted: " + (targetColumn?.name)!
        self.mlDataTableProvider = mlDataProviderContext.mlDataTableProvider
        self.regressorTable = self.mlDataTableProvider.mlDataTable
        let minorityColumn = regressorTable![targetColumn!.name!]
        let minorityMask = minorityColumn == 0
        let minorityTable = self.regressorTable![minorityMask]
        let debit = (self.regressorTable!.rows.count - minorityTable.rows.count) / minorityTable.rows.count
        for _ in 0..<0 {
            regressorTable?.append(contentsOf: minorityTable)
        }
        self.regressorTable!.removeColumn(named: predictedColumnName)
        self.regressorTable!.removeColumn(named: columnDataModel.primaryKeyColumn!.name!)
        self.targetColumnName = self.mlDataTableProvider.orderedColumns.first(where: { $0.istarget == 1})?.name!
        self.timeSeriesColumnName = self.mlDataTableProvider.orderedColumns.first(where: { $0.istimeseries == 1})?.name
        if self.timeSeriesColumnName != nil {
            let timeSeriesColumn = self.regressorTable![timeSeriesColumnName!]
            let seriesEnd = Int((model.model2lastLearningTimeSlice?.value)!)
            let endMask = timeSeriesColumn <= seriesEnd
            self.regressorTable = self.regressorTable![endMask]
        }
        
    }
    public mutating func createModel(algorithmName: String, completion: @escaping () -> Void) -> Void {
        let columnDataModel = ColumnsModel(model: self.model )
        let targetColumn = columnDataModel.timedependantTargetColums.first
        let predictedColumnName = "Predicted: " + (targetColumn?.name)!
        if self.regressorTable!.columnNames.contains(predictedColumnName) {
            self.regressorTable!.removeColumn(named: predictedColumnName)
        }
        //        this sets aside 20% of each model’s data rows for evaluation, leaving the remaining 80% for training.
        let (regressorEvaluationTable, regressorTrainingTable) = regressorTable!.randomSplit(by: 0.2, seed: 5)
        switch algorithmName {
        case "MLLinearRegressor":
            let defaultParams = MLLinearRegressor.ModelParameters(validation: .split(strategy: .automatic), maxIterations: 300, l1Penalty: 0, l2Penalty: 0.001, stepSize: 0.001, convergenceThreshold: 0.001, featureRescaling: true)
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
            let defaultParams = MLRandomForestRegressor.ModelParameters(validation: .split(strategy: .automatic), maxDepth: 100, maxIterations: 300, minLossReduction: 0, minChildWeight: 0.01, randomSeed: 42, rowSubsample: 0.8, columnSubsample: 0.8)
            regressor = {
                do {
                    return try MLRegressor.randomForest(MLRandomForestRegressor(trainingData: regressorTrainingTable, targetColumn: self.targetColumnName, parameters: defaultParams))
                } catch {
                    fatalError(error.localizedDescription)
                }
            }()
        case "MLBoostedTreeRegressor":
            let defaultParams = MLBoostedTreeRegressor.ModelParameters(validation: .split(strategy: .automatic) , maxDepth: 300, maxIterations: 500, minLossReduction: 0, minChildWeight: 0.01, randomSeed: 42, stepSize: 0.05, earlyStoppingRounds: nil, rowSubsample: 0.8, columnSubsample: 0.8)
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
                    return try MLClassifier.supportVector(MLSupportVectorClassifier(trainingData: regressorTrainingTable, targetColumn: targetColumnName, parameters: defaultParams))
                } catch {
                    fatalError(error.localizedDescription)
                }
            }()
        case "MLBoostedTreeClassifier":
            let defaultParams = MLBoostedTreeClassifier.ModelParameters(validation: .split(strategy: .automatic) , maxDepth: 100, maxIterations: 300, minLossReduction: 0, minChildWeight: 0.01, randomSeed: 42, stepSize: 0.01, earlyStoppingRounds: nil, rowSubsample: 0.8, columnSubsample: 0.8)
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
            
            let defaultParams = MLDecisionTreeClassifier.ModelParameters(validation:.split(strategy: .automatic) , maxDepth: 100, minLossReduction: 0, minChildWeight: 0.01, randomSeed: 42)
            classifier = {
                do {
                    return try MLClassifier.decisionTree(MLDecisionTreeClassifier(trainingData: regressorTrainingTable, targetColumn: self.targetColumnName, parameters: defaultParams))
                } catch {
                    fatalError(error.localizedDescription)
                }
            }()
        default:
            print("not found: \(algorithmName)" )
        }
        if regressor != nil {
            let group = DispatchGroup()
            group.enter()
            writeRegressorMetrics(regressor: regressor, regressorName:  algorithmName, regressorEvaluationTable: regressorEvaluationTable) {
                print("Writing completed.")
                group.leave()
            }
            group.wait()
        }
        if classifier != nil {
            do {
                let classifierMetaData = MLModelMetadata(author: "Steps.IT",
                                                         shortDescription: "Vorhersage des Kündigungsverhaltens von Kunden via Classifier",
                                                         version: "1.0")
                try classifier.write(to: mlDataTableProviderContext.lookAheadPath!, metadata: classifierMetaData)
                writeClassifierMetrics(classifier: classifier, classifierName: algorithmName, classifierEvaluationTable: regressorEvaluationTable)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
        completion()
    }
    private func writeClassifierMetrics(classifier: MLClassifier, classifierName: String, classifierEvaluationTable: MLDataTable) -> Void {
        print("to be done")
    }
    private func writeRegressorMetrics (regressor: MLRegressor, regressorName: String, regressorEvaluationTable: MLDataTable, completion: @escaping()->()) -> Void {
        let regressorKPI = Ml_RegressorMetricKPI()
        regressorKPI.dictOfMetrics["trainingMetrics.maximumError"]? = regressor.trainingMetrics.maximumError
        regressorKPI.dictOfMetrics["trainingMetrics.rootMeanSquaredError"]? = regressor.trainingMetrics.rootMeanSquaredError
        regressorKPI.dictOfMetrics["validationMetrics.maximumError"]? = regressor.validationMetrics.maximumError
        regressorKPI.dictOfMetrics["validationMetrics.rootMeanSquaredError"]? = regressor.validationMetrics.rootMeanSquaredError
        /// Evaluation
        let regressorEvalutation = regressor.evaluation(on: regressorTable!)
        regressorKPI.dictOfMetrics["evaluationMetrics.maximumError"]? = regressorEvalutation.maximumError
        regressorKPI.dictOfMetrics["evaluationMetrics.rootMeanSquaredError"]? = regressorEvalutation.rootMeanSquaredError

        regressorKPI.postMetric(prediction: self.mlDataTableProvider.prediction!, algorithmName: self.mlDataTableProvider.regressorName!, lookAhead: self.mlDataTableProviderContext.lookAhead)
        let regressorMetadata = MLModelMetadata(author: "Steps.IT",
                                                shortDescription: "Vorhersage des Kündigungsverhaltens von Kunden",
                                                version: "1.0")

        do {
            try regressor.write(to: mlDataTableProviderContext.lookAheadPath!,
                                metadata: regressorMetadata)
            completion()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
}

