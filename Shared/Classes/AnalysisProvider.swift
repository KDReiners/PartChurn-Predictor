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
    init(model: Models) {
        self.model = model
        let composer = FileWeaver(model: model)
        self.mlDataTableProvider = MlDataTableProvider()
        self.mlDataTableProvider.mlDataTable = composer.mlDataTable_Base!
        self.mlDataTableProvider.orderedColumns = composer.orderedColumns!
        self.mlDataTableProvider.model = self.model
    }
    func explode() -> Void {
        var i = 0
        predictionsDataModel = PredictionsModel(model: self.model)
        /// Gets all predictionClusters associated with the model
        predictionsDataModel.predictions(model: self.model)
        /// Iterate through all clusters
        for cluster in predictionsDataModel.arrayOfPredictions {
            i += 1
            let newAnalysis = Analysis(clusterSelection: cluster, mlDataTableProvider: self.mlDataTableProvider)
            print(cluster.groupingPattern!)
            newAnalysis.analyse()
        }
    }
}
struct Analysis {
    var clusterSelection: PredictionsModel.predictionCluster
    var mlDataTableProvider: MlDataTableProvider!
    init(clusterSelection: PredictionsModel.predictionCluster, mlDataTableProvider: MlDataTableProvider) {
        self.clusterSelection = clusterSelection
        self.mlDataTableProvider = mlDataTableProvider
        
    }
    func analyse() {
        let semp = DispatchSemaphore(value: 0)
        for item in AlgorithmsModel().items {
            mlDataTableProvider.regressorName = item.name!
            mlDataTableProvider.prediction = clusterSelection.prediction
            self.mlDataTableProvider.mlDataTableRaw = nil
            self.mlDataTableProvider.mlDataTable = self.mlDataTableProvider.buildMlDataTable().mlDataTable
            self.mlDataTableProvider.updateTableProvider()
            var trainer = Trainer(mlDataTableFactory: self.mlDataTableProvider)
            trainer.createModel(regressorName: item.name!)
            self.mlDataTableProvider.valuesTableProvider?.regressorName = item.name!
            semp.signal()
            //            self.mlDataTableProvider.updateTableProvider()
            
        }
        semp.wait()
    }
}
