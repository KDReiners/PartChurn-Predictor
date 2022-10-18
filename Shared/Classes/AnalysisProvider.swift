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
    var analyises = [Analysis]()
    init(model: Models) {
        self.model = model
        self.fileWeaver = FileWeaver(model: model)
        self.mlDataTableProvider = MlDataTableProvider()
        self.mlDataTableProvider.mlDataTable = fileWeaver.mlDataTable_Base!
        self.mlDataTableProvider.orderedColumns = fileWeaver.orderedColumns!
        self.mlDataTableProvider.model = self.model
    }
    func explode() -> Void {
        PredictionMetricsModel().deleteAllRecords(predicate: nil)
        PredictionMetricValueModel().deleteAllRecords(predicate: nil)
        var i = 0
        predictionsDataModel = PredictionsModel(model: self.model)
        /// Gets all predictionClusters associated with the model
        predictionsDataModel.predictions(model: self.model)
        /// Iterate through all clusters
        for cluster in predictionsDataModel.arrayOfPredictions {
            i += 1
            let newAnalysis = Analysis(clusterSelection: cluster, mlDataTableProvider: self.mlDataTableProvider, fileWeaver: self.fileWeaver)
            print(cluster.groupingPattern!)
            analyises.append(newAnalysis)
        }
    }
}
struct Analysis {
    var clusterSelection: PredictionsModel.predictionCluster
    var mlDataTableProvider: MlDataTableProvider!
    init(clusterSelection: PredictionsModel.predictionCluster, mlDataTableProvider: MlDataTableProvider, fileWeaver: FileWeaver) {
        self.mlDataTableProvider = mlDataTableProvider
        self.clusterSelection = clusterSelection
        self.mlDataTableProvider.selectedColumns = clusterSelection.columns
        if clusterSelection.connectedTimeSeries.count > 0 {
            let timeSeriesRows = clusterSelection.connectedTimeSeries
            var selectedTimeSeries = [[Int]]()
            for row in timeSeriesRows {
                let innerResult = row.components(separatedBy: ", ").map { Int($0)! }
                selectedTimeSeries.append(innerResult)
            }
            self.mlDataTableProvider.timeSeries = selectedTimeSeries
        } else {
            self.mlDataTableProvider.timeSeries = nil
        }
        self.mlDataTableProvider.mlDataTable = fileWeaver.mlDataTable_Base
        self.mlDataTableProvider.orderedColumns = fileWeaver.orderedColumns!
        self.mlDataTableProvider.selectedColumns = clusterSelection.columns
        self.mlDataTableProvider.prediction = clusterSelection.prediction
        self.mlDataTableProvider = mlDataTableProvider
        prepare()
    }
    func prepare() {
        /// From compositionsView.generateValuesView
        self.mlDataTableProvider.mlDataTableRaw = nil
        self.mlDataTableProvider.mlDataTable = self.mlDataTableProvider.buildMlDataTable().mlDataTable
        self.mlDataTableProvider.updateTableProvider()
        analyse()
    }
    func analyse() {
        for item in AlgorithmsModel().items {
            print("Working on algorithm: \(item.name!)")
            mlDataTableProvider.regressorName = item.name!
            mlDataTableProvider.prediction = clusterSelection.prediction
            var trainer = Trainer(mlDataTableFactory: self.mlDataTableProvider)
            trainer.createModel(regressorName: item.name!)
            let newStatistics = Statistics(mlOwnDataTableProvider: self.mlDataTableProvider, regressorName: item.name!)
            let group = DispatchGroup()
            group.enter()
            newStatistics.schedule(group: group)
        }
    }
}
struct Statistics {
    var mlOwnDataTableProvider: MlDataTableProvider
    var regressorName: String
    init(mlOwnDataTableProvider: MlDataTableProvider, regressorName: String) {
        self.mlOwnDataTableProvider = mlOwnDataTableProvider
        self.mlOwnDataTableProvider.valuesTableProvider?.regressorName = regressorName
        self.regressorName = regressorName
    }
    func schedule(group: DispatchGroup) {
        let group = DispatchGroup()
        update(group: group) {
            print("\(regressorName) ready")
        }
        group.notify(queue: DispatchQueue.global()) {
            print("Completed work)")
          }
    }
    func update(group:  DispatchGroup, completion: @escaping() -> ()) -> Void {
        mlOwnDataTableProvider.updateTableProvider()
        group.enter()
        
    }
}
