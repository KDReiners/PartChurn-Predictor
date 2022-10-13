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
    init(model: Models) {
        self.model = model
    }
    func explode() -> Void {
        predictionsDataModel = PredictionsModel(model: self.model)
        /// Gets all predictionClusters associated with the model
        predictionsDataModel.predictions(model: self.model)
        /// Iterate through all clusters
        for cluster in predictionsDataModel.arrayOfPredictions {
            let newAnalysis = Analysis(clusterSelection: cluster)
        }
    }
}
class Analysis {
    var composition: Compositions!
    var clusterSelection: PredictionsModel.predictionCluster
    init(clusterSelection: PredictionsModel.predictionCluster) {
        self.clusterSelection = clusterSelection
    }
    
}
