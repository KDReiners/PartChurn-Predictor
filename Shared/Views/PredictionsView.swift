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
    var performanceDataProvider: PerformanceDataProvider!
    init(model: Models) {
        self.model = model
        self.performanceDataProvider = PerformanceDataProvider(model: self.model)
        algorithmTypeDataModel.setUp()
    }
    var body: some View {
        ScrollView(.horizontal) {
            Table(performanceDataProvider.PredictionKPIS) {
                Group {
                    performanceDataProvider.timeSliceFrom
                    performanceDataProvider.timeSliceTo
                    performanceDataProvider.involvedColumns
                    performanceDataProvider.columnsCount
                    performanceDataProvider.lookAhead
                    performanceDataProvider.timeSlices
                    performanceDataProvider.algorithm
                    performanceDataProvider.precision
                    performanceDataProvider.recall
                    performanceDataProvider.f1Score
                }
                Group {
                    performanceDataProvider.specifity
                    performanceDataProvider.falseNegatives
                    performanceDataProvider.falsePositives
                    performanceDataProvider.trueNegatives
                    performanceDataProvider.truePositives
                    performanceDataProvider.simulation
                }
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
