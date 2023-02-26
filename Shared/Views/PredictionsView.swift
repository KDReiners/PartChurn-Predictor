//
//  PredictionsView.swift
//  PartChurn Predictor
//--
//  Created by Reiners, Klaus Dieter on 17.01.23.
//

import SwiftUI
struct PredictionsView: View {
    var model: Models
    var algorithmTypeDataModel = AlgorithmTypesModel()
    var tabularDataProvider: PerformanceDataProvider!
    init(model: Models) {
        self.model = model
        self.tabularDataProvider = PerformanceDataProvider(model: self.model)
        algorithmTypeDataModel.setUp()
    }
    var body: some View {
        ScrollView(.horizontal) {
            Table(tabularDataProvider.PredictionKPIS) {
                Group {
                    tabularDataProvider.involvedColumns
                    tabularDataProvider.algorithm
                    tabularDataProvider.timeSlices
                    tabularDataProvider.simulation
//                    TableColumn("DataSetType", value: \TabularDataProvider.PredictionKPI.dataSetType)
//                    TableColumn("RootMean", value: \TabularDataProvider.PredictionKPI.rootMeanSquaredError!)
//                    TableColumn("Maximum", value: \TabularDataProvider.PredictionKPI.maximumError!)
//                    TableColumn("T->Population", value: \TabularDataProvider.PredictionKPI.targetPopulation!)
//                    TableColumn("T->Optimum", value: \TabularDataProvider.PredictionKPI.targetsAtOptimum!)
//                    TableColumn("D->Optimum", value: \TabularDataProvider.PredictionKPI.dirtiesAtOptimum!)
//                    TableColumn("PV->Optimum", value: \TabularDataProvider.PredictionKPI.predictionValueAtOptimum!)
//                    TableColumn("T->Threshold", value: \TabularDataProvider.PredictionKPI.targetsAtThreshold!)
                }
//                Group {
//                    TableColumn("D->Threshold", value: \TabularDataProvider.PredictionKPI.dirtiesAtThreshold!)
//                    TableColumn("PV->Threshold", value: \TabularDataProvider.PredictionKPI.predictionValueAtThreshold!)
//                }

            }
            .frame(minWidth: 1500, idealWidth: 2000, maxWidth: .infinity)
        }
    }
}

struct PredictionsView_Previews: PreviewProvider {
    static var previews: some View {
        PredictionsView(model: ModelsModel().items.first!)
    }
}
