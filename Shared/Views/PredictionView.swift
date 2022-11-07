//
//  CompositionView.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 06.11.22.
//

import SwiftUI

struct PredictionView: View {
    var predictionsDataModel = PredictionsModel()
    var prediction: Predictions!
    @State var composer: FileWeaver!
    @State var combinator: Combinator!
    @State var clusterSelection: PredictionsModel.predictionCluster?
    var mlDataTableProvider: MlDataTableProvider
    @State var valuesView: ValuesView?
    init(prediction: Predictions?) {
        self.mlDataTableProvider = MlDataTableProvider()
        guard let prediction = prediction else {
           return
        }
        self.prediction = prediction
    }
    var body: some View {
        Text("Hello dear prediction").onAppear {
            predictionsDataModel.predictions(model: self.prediction.prediction2model!)
            predictionsDataModel.getTimeSeries()
            clusterSelection = predictionsDataModel.arrayOfPredictions.first(where: { $0.prediction == prediction })
            self.composer = FileWeaver(model: self.prediction.prediction2model!)
            self.combinator = Combinator(model: self.prediction.prediction2model!, orderedColumns: (composer?.orderedColumns)!, mlDataTable: (composer?.mlDataTable_Base)!)
            self.mlDataTableProvider.mlDataTable = composer?.mlDataTable_Base
            self.mlDataTableProvider.orderedColumns = composer?.orderedColumns!
            generateValuesView()
            valuesView = ValuesView(mlDataTableProvider: self.mlDataTableProvider)
        }
        valuesView
    }
    func generateValuesView() {
        if let timeSeriesRows = self.clusterSelection?.connectedTimeSeries {
            var selectedTimeSeries = [[Int]]()
            for row in timeSeriesRows {
                let innerResult = row.components(separatedBy: ", ").map { Int($0)! }
                selectedTimeSeries.append(innerResult)
            }
            self.mlDataTableProvider.timeSeries = selectedTimeSeries
        } else {
            self.mlDataTableProvider.timeSeries = nil
        }
        self.mlDataTableProvider.mlDataTableRaw = nil
        self.mlDataTableProvider.prediction = self.prediction
        self.mlDataTableProvider.mlDataTable = self.mlDataTableProvider.buildMlDataTable().mlDataTable
        self.mlDataTableProvider.updateTableProvider()
        self.mlDataTableProvider.loaded = false
    }
}
