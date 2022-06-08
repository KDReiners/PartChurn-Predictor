//
//  Traines.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 09.05.22.
//

import Foundation
import CreateML
public struct Trainer {
    let csvFile = Bundle.main.url(forResource: "ChurnPrediction_POC", withExtension: "csv")!
    let regressorColumns = ["Kunde_seit",
                            "Account_Manager",
                            "Anzahl_Arbeitsplaetze",
                            "ADDISON",
                            "AKTE",
                            "SBS",
                            "Anzahl_UHD",
                            "davon geloest",
                            "Jahresfaktura",
                            "Anzahl_OPPs",
                            "Digitalisierungsgrad",
                            "Kuendigt"]
    
    var dataTable: MLDataTable?
    var regressorTable: MLDataTable?
    var file: Files?
    var model: Models?
    init(baseTable: MLDataTable? = nil) {
        dataTable = try! MLDataTable(contentsOf: csvFile)
        if baseTable == nil {
            regressorTable = dataTable![regressorColumns]
        } else {
            regressorTable = baseTable![regressorColumns]
        }
        
        file = FilesModel().items.first(where: {
            return $0.name == csvFile.lastPathComponent
        })
        model = file?.files2model
        guard dataTable != nil else {
            return
        }
        guard file != nil else {
            return
        }
        guard model != nil else {
            return
        }



        
    }
    public func createModel(regressorName: String) -> Void {
        let (regressorEvaluationTable, regressorTrainingTable) = regressorTable!.randomSplit(by: 0.20, seed: 5)
        switch regressorName {
        case "MLLinearRegressor": trainMLLinearRegressor(regressorEvaluationTable: regressorEvaluationTable, regressorTrainingTable: regressorTrainingTable)
        case "MLDecisionTreeRegressor":
            return
        case "MLRandomForestRegressor":
            return
        case "MLBoostedTreeRegressor":
            return
        default:
            fatalError()
        }
    }
    private func trainMLLinearRegressor(regressorEvaluationTable: MLDataTable, regressorTrainingTable: MLDataTable) -> Void {
        let regressorKPI = Ml_MetricKPI()
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
//            let desktopPath = homePath.appendingPathComponent("Desktop")

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
