//
//  MLExplainEntry.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 20.03.23.
//

import Foundation
struct MLExplainEntry {
    var prediction: Predictions!
    var columnsDataModel: ColumnsModel!
    var algorithm: Algorithms!
    init(prediction: Predictions!, algorithm: Algorithms) {
        self.prediction = prediction
        self.algorithm = algorithm
        self.columnsDataModel = ColumnsModel(model: prediction.prediction2model)
    }
    
}
