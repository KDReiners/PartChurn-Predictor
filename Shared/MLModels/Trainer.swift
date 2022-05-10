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
    init() {
        dataTable = try? MLDataTable(contentsOf: csvFile)
        regressorTable = dataTable![regressorColumns]
        
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
    private func trainMLLinearRegressor(regressorEvaluationTable: MLDataTable, regressorTrainingTable: MLDataTable) {
        var regressor: MLLinearRegressor
        do {
            regressor = try MLLinearRegressor(trainingData: regressorTrainingTable,
                                              targetColumn: "Kuendigt")
            let worstTrainingError = regressor.trainingMetrics.maximumError
            let worstValidationError = regressor.validationMetrics.maximumError
            let regressorEvalutation = regressor.evaluation(on: regressorEvaluationTable)

            /// Die größte Distanz zwichen Vorhersage und Wert
            let worstEvaluationError = regressorEvalutation.maximumError
            /// Pfad zum Schreibtisch
            let homePath = FileManager.default.homeDirectoryForCurrentUser
            let desktopPath = homePath //.appendingPathComponent("Desktop")

            let regressorMetadata = MLModelMetadata(author: "Steps.IT",
                                                    shortDescription: "Vorhersage des Kündigungsverhaltens von Kunden",
                                                    version: "1.0")
            /// Speichern des trainierten Modells auf dem Schreibtisch
            try? regressor.write(to: desktopPath.appendingPathComponent("LinearPredictor.mlmodel"),
                                metadata: regressorMetadata)
            
        } catch {
            print(error)
        }
        
        

    }
}
