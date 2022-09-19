//
//  Traines.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 09.05.22.
//

import Foundation
import CreateML
import CoreML
public struct Trainer {
    var mlDataTableProvider: MlDataTableProvider!
    var regressorTable: MLDataTable?
    var coreDataML: CoreDataML!
    var file: Files?
    var model: Models!
    var targetColumnName: String!
    var regressor: MLRegressor!
    var prediction: Predictions!
    init(mlDataTableFactory: MlDataTableProvider) {
        self.mlDataTableProvider = mlDataTableFactory
        self.regressorTable = self.mlDataTableProvider.mlDataTable
        self.targetColumnName = self.mlDataTableProvider.orderedColumns.first(where: { $0.istarget == 1})?.name!
        
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
        let (regressorEvaluationTable, regressorTrainingTable) = regressorTable!.randomSplit(by: 0.2, seed: 5)
        switch regressorName {
        case "MLLinearRegressor":
            let defaultParams = MLLinearRegressor.ModelParameters(validation: .split(strategy: .automatic), maxIterations: 50, l1Penalty: 0, l2Penalty: 0.01, stepSize: 1.0, convergenceThreshold: 0.01, featureRescaling: true)
            regressor = {
                do {
                    return try MLRegressor.linear(MLLinearRegressor(trainingData: regressorTrainingTable,
                                                                            targetColumn: self.targetColumnName, parameters: defaultParams))
                } catch {
                    fatalError(error.localizedDescription)
                }
            }()
        case "MLDecisionTreeRegressor":
            
            let defaultParams = MLDecisionTreeRegressor.ModelParameters(validation:.split(strategy: .automatic) , maxDepth: 100, minLossReduction: 0, minChildWeight: 0.1, randomSeed: 42)
            regressor = {
                do {
                    return try MLRegressor.decisionTree(MLDecisionTreeRegressor(trainingData: regressorTrainingTable, targetColumn: self.targetColumnName, parameters: defaultParams))
                } catch {
                    fatalError(error.localizedDescription)
                }
            }()
        case "MLRandomForestRegressor":
            let defaultParams = MLRandomForestRegressor.ModelParameters(validation: .split(strategy: .automatic), maxDepth: 100, maxIterations: 5000, minLossReduction: 0, minChildWeight: 0.1, randomSeed: 42, rowSubsample: 0.8, columnSubsample: 0.8)
            regressor = {
                do {
                    return try MLRegressor.randomForest(MLRandomForestRegressor(trainingData: regressorTrainingTable, targetColumn: self.targetColumnName, parameters: defaultParams))
                } catch {
                    fatalError(error.localizedDescription)
                }
            }()
        case "MLBoostedTreeRegressor":
            let defaultParams = MLBoostedTreeRegressor.ModelParameters(validation: .split(strategy: .automatic) , maxDepth: 100, maxIterations: 5000, minLossReduction: 0, minChildWeight: 0.1, randomSeed: 42, stepSize: 0.3, earlyStoppingRounds: nil, rowSubsample: 1.0, columnSubsample: 1.0)
            regressor =  {
                do {
                    return try MLRegressor.boostedTree(MLBoostedTreeRegressor(trainingData: regressorTrainingTable,
                                                                              targetColumn: targetColumnName, parameters: defaultParams ))
                } catch {
                    fatalError(error.localizedDescription)
                }
            }()
        default:
            fatalError()
        }
        writeMetrics(regressor: regressor, regressorName:  regressorName, regressorEvaluationTable: regressorEvaluationTable)
        
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
        try? regressor.write(to: BaseServices.homePath.appendingPathComponent((self.mlDataTableProvider.model?.name!)!, isDirectory: true).appendingPathComponent(regressorName + "_" + self.mlDataTableProvider.prediction!.id!.uuidString + ".mlmodel"),
                            metadata: regressorMetadata)
    }
}

