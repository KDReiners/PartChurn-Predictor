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
    init() {
        dataTable = try? MLDataTable(contentsOf: csvFile)
        regressorTable = dataTable![regressorColumns]
        file = FilesModel().items.first(where: {
            return $0.name == csvFile.lastPathComponent
        })
        model = file?.files2model
        
    }
    public func createModel(regressorName: String) -> Void {
        var metric: Ml_MetricKPI?
        let (regressorEvaluationTable, regressorTrainingTable) = regressorTable!.randomSplit(by: 0.20, seed: 5)
        switch regressorName {
        case "MLLinearRegressor": metric = trainMLLinearRegressor(regressorEvaluationTable: regressorEvaluationTable, regressorTrainingTable: regressorTrainingTable)
        case "MLDecisionTreeRegressor":
            return
        case "MLRandomForestRegressor":
            return
        case "MLBoostedTreeRegressor":
            return
        default:
            fatalError()
        }
        guard let metric = metric else {
            return
        }
        postMetric(metric: metric)
    }
    private func trainMLLinearRegressor(regressorEvaluationTable: MLDataTable, regressorTrainingTable: MLDataTable) -> Ml_MetricKPI {
        var regressorKPI = Ml_MetricKPI()
        var regressor: MLLinearRegressor
        do {
            
            regressor = try MLLinearRegressor(trainingData: regressorTrainingTable,
                                              targetColumn: "Kuendigt")
            regressorKPI.worstTrainingError = regressor.trainingMetrics.maximumError
            regressorKPI.trainingRootMeanSquaredError = regressor.trainingMetrics.rootMeanSquaredError
            
            regressorKPI.worstValidationError = regressor.validationMetrics.maximumError
            regressorKPI.validatitionRootMeanSquaredError = regressor.validationMetrics.rootMeanSquaredError
            
            let regressorEvalutation = regressor.evaluation(on: regressorEvaluationTable)

            /// Die größte Distanz zwichen Vorhersage und Wert
            regressorKPI.worstEvalutationError = regressorEvalutation.maximumError
            regressorKPI.evaluationRootMeanSquaredError = regressorEvalutation.rootMeanSquaredError
            
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
       
        return regressorKPI

    }
    private func postMetric(metric: Ml_MetricKPI) {
        let metricsvaluesModel = MetricvaluesModel()
        let datasetTypeModel = DatasettypesModel()
        let metricsModel = MetricsModel()
        
        // Training
        let datasetType = datasetTypeModel.items.first(where: {
            return $0.name == "training"
        })
        let metricType = metricsModel.items.first(where: {
            return $0.name == "worstError"
        })
        guard let datasetType = datasetType else {
            return
        }
        guard let metricType = metricType else {
            return
        }

        
        let newMetric = metricsvaluesModel.insertRecord()
        newMetric.metricvalue2model = model
        newMetric.metricvalue2file = file
        newMetric.value = metric.worstTrainingError
        newMetric.metricvalue2metric?.metric2datasettypes?.addingObjects(from: NSSet(array:[datasetType]) as! Set<AnyHashable>)
        metricsvaluesModel.saveChanges()
        metricType.metric2metricvalues = metricType.metric2metricvalues?.addingObjects(from: [newMetric]) as NSSet?
        datasetTypeModel.saveChanges()
        metricsModel.saveChanges()
        
    }
}
