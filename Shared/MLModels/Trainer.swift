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
    var regressorTable: MLDataTable?
    var coreDataML: CoreDataML!
    var file: Files?
    var model: Models?
    var targetColumnName: String!
    init(model: Models) {
        self.model = model
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
    public func createModel(regressorName: String) -> Void {
        let (regressorEvaluationTable, regressorTrainingTable) = regressorTable!.randomSplit(by: 0.20, seed: 5)
        switch regressorName {
        case "MLLinearRegressor":
            guard let regressor = try? MLRegressor.linear(MLLinearRegressor(trainingData: regressorTrainingTable,
                                                                            targetColumn: self.targetColumnName)) else { return }
            writeMetrics(regressor: regressor, regressorName: regressorName, regressorEvaluationTable: regressorEvaluationTable)
        case "MLDecisionTreeRegressor":
            let params = MLDecisionTreeRegressor.ModelParameters(maxDepth: 100, minLossReduction: 0.01, minChildWeight: 0.01, randomSeed: 10)
            guard let regressor = try? MLRegressor.decisionTree(MLDecisionTreeRegressor(trainingData: regressorTrainingTable, targetColumn: self.targetColumnName, parameters: params)) else { return }
            writeMetrics(regressor: regressor, regressorName: regressorName, regressorEvaluationTable: regressorEvaluationTable)
        case "MLRandomForestRegressor":
            let params = MLRandomForestRegressor.ModelParameters(maxIterations: 5000)
            guard let regressor = try? MLRegressor.randomForest(MLRandomForestRegressor(trainingData: regressorTrainingTable, targetColumn: self.targetColumnName, parameters: params)) else { return }
            writeMetrics(regressor: regressor, regressorName: regressorName, regressorEvaluationTable: regressorEvaluationTable)
        case "MLBoostedTreeRegressor":
            let params = MLBoostedTreeRegressor.ModelParameters(maxIterations: 5000)
            guard let regressor = try? MLRegressor.boostedTree(MLBoostedTreeRegressor(trainingData: regressorTrainingTable,
                                                                             targetColumn: targetColumnName, parameters: params as! MLBoostedTreeRegressor.ModelParameters)) else { return}
            writeMetrics(regressor: regressor, regressorName: regressorName, regressorEvaluationTable: regressorEvaluationTable)
        default:
            fatalError()
        }
        
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
        regressorKPI.postMetric(model: model!, file: file, algorithmName: regressorName)
        let regressorMetadata = MLModelMetadata(author: "Steps.IT",
                                                shortDescription: "Vorhersage des Kündigungsverhaltens von Kunden",
                                                version: "1.0")
        /// Speichern des trainierten Modells auf dem Schreibtisch
        try? regressor.write(to: BaseServices.homePath.appendingPathComponent(regressorName+".mlmodel"),
                            metadata: regressorMetadata)
    }
}
