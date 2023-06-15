//
//  AnalysisProvider.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 13.10.22.
//

import Foundation
class AnalysisProvider {
    var model: Models
    var predictionsDataModel: PredictionsModel!
    var analysises: [Analysis]!
    var mlDataTableProvider: MlDataTableProvider!
    var fileWeaver: FileWeaver!
    init(model: Models) {
        self.model = model
        self.fileWeaver = FileWeaver(model: model, lookAhead: 0)
        self.mlDataTableProvider = MlDataTableProvider(model: self.model)
        self.mlDataTableProvider.mlDataTable = fileWeaver.mlDataTable_Base!
        self.mlDataTableProvider.orderedColumns = fileWeaver.orderedColumns!
        PredictionMetricsModel().deleteAllRecords(predicate: nil)
        PredictionMetricValueModel().deleteAllRecords(predicate: nil)
        PredictionMetricsModel().deleteAllRecords(predicate: nil)
        MetricvaluesModel().deleteAllRecords(predicate: nil)
    }
    func explode() -> Void {
        PredictionMetricsModel().deleteAllRecords(predicate: nil)
        PredictionMetricValueModel().deleteAllRecords(predicate: nil)
        var i = 0
        predictionsDataModel = PredictionsModel(model: self.model)
        /// Gets all predictionClusters associated with the model
        predictionsDataModel.createPredictionForModel(model: self.model)
        /// Iterate through all clusters
        for cluster in predictionsDataModel.arrayOfPredictions {
            i += 1
            _ = Analysis(clusterSelection: cluster, fileWeaver: self.fileWeaver)
        }
    }
}
struct Analysis {
    var clusterSelection: PredictionsModel.PredictionCluster
    var fileWeaver: FileWeaver
    init(clusterSelection: PredictionsModel.PredictionCluster, fileWeaver: FileWeaver) {
        self.fileWeaver = fileWeaver
        self.clusterSelection = clusterSelection
        analyse()
    }
    func createTableForExplosion(fileWeaver: FileWeaver, clusterSelection: PredictionsModel.PredictionCluster) -> MlDataTableProvider{
        let result = MlDataTableProvider()
        result.mlDataTable = fileWeaver.mlDataTable_Base!
        result.orderedColumns = fileWeaver.orderedColumns!
        result.model = fileWeaver.model
        result.selectedColumns = clusterSelection.columns
        result.prediction = clusterSelection.prediction
        if clusterSelection.connectedTimeSeries.count > 0 {
            let timeSeriesRows = clusterSelection.connectedTimeSeries
            var selectedTimeSeries = [[Int]]()
            for row in timeSeriesRows {
                let innerResult = row.components(separatedBy: ", ").map { Int($0)! }
                selectedTimeSeries.append(innerResult)
            }
            result.timeSeries = selectedTimeSeries
        } else {
            result.timeSeries = nil
        }
        result.mlDataTableRaw = nil
        result.mlDataTable = try? result.buildMlDataTable().mlDataTable
        result.updateTableProvider()
        return result
    }
    func analyse() {
        for item in AlgorithmsModel().items.filter( { $0.name == "MLBoostedTreeRegressor"}) {
            let mlDataTableProvider = createTableForExplosion(fileWeaver: self.fileWeaver, clusterSelection: self.clusterSelection)
            mlDataTableProvider.regressorName = item.name!
            mlDataTableProvider.prediction = clusterSelection.prediction
            var trainer = Trainer(mlDataTableProvider: mlDataTableProvider, model: mlDataTableProvider.model!)
            trainer.createModel(algorithmName: item.name!)
            mlDataTableProvider.updateTableProvider()
            mlDataTableProvider.loaded = false
        }
    }
}
//struct Statistics {
//    var mlOwnDataTableProvider: MlDataTableProvider
//    var regressorName: String
//    init(mlOwnDataTableProvider: MlDataTableProvider, regressorName: String) {
//        self.mlOwnDataTableProvider = mlOwnDataTableProvider
//        self.mlOwnDataTableProvider.valuesTableProvider?.regressorName = regressorName
//        self.mlOwnDataTableProvider.updateTableProviderForStatistics {
//           print("ready")
//
//        }
//        self.regressorName = regressorName
//    }
//    func schedule() {
//        update() {
//            print("\(regressorName) ready")
//        }
//    }
//    func update(completion: @escaping() -> ()) -> Void {
//        mlOwnDataTableProvider.updateTableProvider()
//    }
//}
