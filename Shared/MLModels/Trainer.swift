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
    init(model: Models) {
        self.model = model
        coreDataML = CoreDataML(model: model)
        regressorTable = CoreDataML(model: model).mlDataTable
        guard regressorTable != nil else {
            return
        }
    }
    public func createModel(regressorName: String) -> Void {
        let (regressorEvaluationTable, regressorTrainingTable) = regressorTable!.randomSplit(by: 0.20, seed: 5)
        switch regressorName {
        case "MLLinearRegressor":
            trainRegressor(regressorName: regressorName, regressorEvaluationTable: regressorEvaluationTable, regressorTrainingTable: regressorTrainingTable, modelParameter: "none")
        case "MLDecisionTreeRegressor":
            return
        case "MLRandomForestRegressor":
            return
        case "MLBoostedTreeRegressor":
            let params = MLBoostedTreeRegressor.ModelParameters(maxIterations: 5000)
            trainRegressor(regressorName: regressorName, regressorEvaluationTable: regressorEvaluationTable, regressorTrainingTable: regressorTrainingTable, modelParameter: params)
            return
        default:
            fatalError()
        }
    }
    
    private func trainRegressor(regressorName: String, regressorEvaluationTable: MLDataTable, regressorTrainingTable: MLDataTable, modelParameter: Any) -> Void {
        let regressorKPI = Ml_MetricKPI()
        
        var method = try? MLRegressor.boostedTree(MLBoostedTreeRegressor(trainingData: regressorTrainingTable,
                                                                         targetColumn: "Kuendigt", parameters: modelParameter as! MLBoostedTreeRegressor.ModelParameters))
        var regressor: MLLinearRegressor
        do {
            
            /// Training and Validation
            regressor = try MLLinearRegressor(trainingData: regressorTrainingTable,
                                              targetColumn: "Kuendigt")
            regressorKPI.dictOfMetrics["trainingMetrics.maximumError"]? = regressor.trainingMetrics.maximumError
            regressorKPI.dictOfMetrics["trainingMetrics.rootMeanSquaredError"]? = regressor.trainingMetrics.rootMeanSquaredError
            regressorKPI.dictOfMetrics["validationMetrics.maximumError"]? = regressor.validationMetrics.maximumError
            regressorKPI.dictOfMetrics["validationMetrics.rootMeanSquaredError"]? = regressor.validationMetrics.rootMeanSquaredError

            /// Evaluation
            let regressorEvalutation = regressor.evaluation(on: regressorEvaluationTable)
            regressorKPI.dictOfMetrics["evaluationMetrics.maximumError"]? = regressorEvalutation.maximumError
            regressorKPI.dictOfMetrics["evaluationMetrics.rootMeanSquaredError"]? = regressorEvalutation.rootMeanSquaredError
            /// Schreibe in CoreData
            regressorKPI.postMetric(model: model!, file: file!, algorithmName: "MLLinearRegressor")
            /// Pfad zum Schreibtisch
            let homePath = FileManager.default.homeDirectoryForCurrentUser

            let regressorMetadata = MLModelMetadata(author: "Steps.IT",
                                                    shortDescription: "Vorhersage des Kündigungsverhaltens von Kunden",
                                                    version: "1.0")
            /// Speichern des trainierten Modells auf dem Schreibtisch
            try? regressor.write(to: homePath.appendingPathComponent("LinearPredictor.mlmodel"),
                                metadata: regressorMetadata)
            
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
