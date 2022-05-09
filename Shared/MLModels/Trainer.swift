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
        var regressorTable = dataTable![regressorColumns]
        
    }
    public func createModel(regressorName: String) -> Void {
//        let (regressorEvaluationTable, regressorTrainingTable) = regressorTable.randomSplit(by: 0.20, seed: 5)
//        let regressor =
//        switch regressorName {
//        case "MLLinearRegressor":
//        case "MLDecisionTreeRegressor":
//        case "MLRandomForestRegressor":
//        case "MLRandomForestRegressor":
//        case "MLBoostedTreeRegressor":
//            return
//        default:
//            fatalError()
//
//
//        }
    }
}
