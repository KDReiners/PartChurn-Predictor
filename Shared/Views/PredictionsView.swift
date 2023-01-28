//
//  PredictionsView.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 17.01.23.
//

import SwiftUI
struct PredictionsView: View {
    var model: Models
    var metricsTable: [TabularDataProvider.PredictionKPI]
    init(model: Models) {
        self.model = model
        self.metricsTable = TabularDataProvider(model: self.model).PredictionKPIS
    }
    var body: some View {
        ScrollView(.horizontal) {
            Table(metricsTable) {
                Group {
                    TableColumn("GroupingPattern", value: \TabularDataProvider.PredictionKPI.groupingPattern!)
                    TableColumn("Algorithm", value: \TabularDataProvider.PredictionKPI.algorithm!)
                    TableColumn("DataSetType", value: \TabularDataProvider.PredictionKPI.dataSetType)
                    TableColumn("RootMeanSquaredError", value: \TabularDataProvider.PredictionKPI.rootMeanSquaredError!)
                    TableColumn("MaximumError", value: \TabularDataProvider.PredictionKPI.maximumError!)
                    TableColumn("TargetInstancesCount", value: \TabularDataProvider.PredictionKPI.targetInstancesCount!)
                    TableColumn("TargetsAtOptimum", value: \TabularDataProvider.PredictionKPI.targetsAtOptimum!)
                    TableColumn("DirtiesAtOptimum", value: \TabularDataProvider.PredictionKPI.dirtiesAtOptimum!)
                    TableColumn("PredictionValueAtOptimum", value: \TabularDataProvider.PredictionKPI.predictionValueAtOptimum!)
                    TableColumn("TargetsAtThreshold", value: \TabularDataProvider.PredictionKPI.targetsAtThreshold!)
                }
                Group {
                    TableColumn("DirtiesAtThreshold", value: \TabularDataProvider.PredictionKPI.dirtiesAtThreshold!)
                    TableColumn("PredictionValueAtThreshold", value: \TabularDataProvider.PredictionKPI.predictionValueAtThreshold!)
                }

            }.frame(width: 2000)
        }
    }
}

struct PredictionsView_Previews: PreviewProvider {
    static var previews: some View {
        PredictionsView(model: ModelsModel().items.first!)
    }
}
