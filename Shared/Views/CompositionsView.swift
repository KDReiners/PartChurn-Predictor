//
//  CompositionsView.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 17.08.22.
//

import SwiftUI

struct CompositionsView: View {
    @ObservedObject var compositionDataModel: CompositionsModel
    @ObservedObject var predictionsDataModel = PredictionsModel()
    @State var mlSelection: String? = nil
    @State var clusterSelection: PredictionsModel.predictionCluster?
    @State var selectedColumnCombination: [Columns]?
    @State var selectedTimeSeriesCombination: [String]?
    
    var model: Models
    var composer: FileWeaver?
    var combinator: Combinator!
    var mlAlgorithms = ["MLLinearRegressor", "MLDecisionTreeRegressor", "MLRandomForestRegressor", "MLBoostedTreeRegressor"]
    
    init(model: Models, composer: FileWeaver, combinator: Combinator) {
        self.model = model
        self.compositionDataModel = CompositionsModel(model: self.model)
        self.composer = composer
        self.combinator = combinator
        compositionDataModel.presentCalculationTasks()
        predictionsDataModel.predictions(model: self.model)
        predictionsDataModel.getTimeSeries()
    }
    var body: some View {
        VStack {
            HStack(alignment: .center)
            {
                VStack(alignment: .leading)
                {
                    HStack(alignment: .center) {
                        Text("Data Cluster")
                        .font(.title)
                        Spacer()
                        if predictionsDataModel.arrayOfPredictions.count > 0 {
                            Button("Delete") {
                                predictionsDataModel.deleteAllRecords(predicate: nil)
                                clusterSelection = nil
                                predictionsDataModel.predictions(model: self.model)
                            }
                        }
                        else if compositionDataModel.arrayOfClusters.count > 0 {
                            Button("Save") {
                                savePredictions()
                            }
                        }
                    }
                    if predictionsDataModel.arrayOfPredictions.count > 0 {
                        List(predictionsDataModel.arrayOfPredictions.sorted(by: { $0.seriesDepth < $1.seriesDepth }), id: \.self, selection: $clusterSelection) { prediction in
                            Text(prediction.groupingPattern!)
                        }
                        
                    }
                    else if compositionDataModel.arrayOfClusters.count > 0 {
                        List(compositionDataModel.arrayOfClusters.sorted(by: { $0.seriesDepth < $1.seriesDepth }), id:\.self) { cluster in
                            Text(cluster.groupingPattern!)
                        }
                    }
                }
                .frame(width: 270)
                .padding()
                
                VStack(alignment: .leading) {
                    if predictionsDataModel.arrayOfPredictions.count > 0 && clusterSelection != nil {
                        Text("Timeseries")
                            .font(.title)
                        List((clusterSelection?.timeSeries.sorted(by: { $0.from < $1.from }))!, id: \.self) { series in
                            Text(String(series.from) + " - " + String(series.to))
                        }
                        Text("Columns")
                            .font(.title)
                        List((clusterSelection?.columns.sorted(by: { $0.orderno < $1.orderno }))!, id:\.self ) { column in
                            Text(column.name!)
                        }
                    }
                }
                .padding()
                VStack(alignment: .leading) {
                    Text("Algorithmus")
                        .font(.title)
                    HStack {
                        List(mlAlgorithms, id: \.self, selection: $mlSelection) { algorithm in
                            Text(algorithm)
                        }.frame(width: 250)
                        VStack{
                            Button("Lerne..") {
                                train(regressorName: mlSelection)
                            }
                            .frame(width: 90)
                            .disabled(mlSelection == nil || clusterSelection == nil)
                        }
                    }
                }
                .padding()
                VStack(alignment: .leading) {
                    Text("Algorithmus KPI")
                        .font(.title)
                    AlgorithmsModel.valueList(prediction: (clusterSelection?.prediction), algorithmName: mlSelection ?? "unbekannt")
                }
            }
            Divider()
            VStack(alignment: .leading) {
                ValuesView(mlDataTable: (composer?.mlDataTable_Base)!, orderedColumns: (composer?.orderedColumns)!, selectedColumns: clusterSelection?.columns, timeSeriesRows: clusterSelection?.connectedTimeSeries)
            }.padding()
        }
    }
    func savePredictions() {
        predictionsDataModel.savePredictions(model: self.model)
    }
    private func train(regressorName: String?) {
        var trainer = Trainer(prediction: (clusterSelection?.prediction)!, mlDataTable: (composer?.mlDataTable_Base)!, orderedColumns: (composer?.orderedColumns)!, selectedColumns: clusterSelection?.columns, timeSeriesRows: clusterSelection?.connectedTimeSeries)
        trainer.createModel(regressorName: $mlSelection.wrappedValue!)
    }
}
