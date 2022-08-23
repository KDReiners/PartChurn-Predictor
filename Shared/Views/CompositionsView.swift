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
    var compositionViewDict: Dictionary<String, [CompositionsViewEntry]>?
    var model: Models
    internal var composer: FileWeaver?
    @State var clusterSelection: PredictionsModel.prediction!
    @State var selectedColumnCombination: [Columns]?
    @State var selectedTimeSeriesCombination: [String]?
    init(model: Models, composer: FileWeaver) {
        self.model = model
        self.compositionDataModel = CompositionsModel(model: self.model)
        self.composer = composer
        compositionDataModel.presentCalculationTasks()
        predictionsDataModel.predictions(model: self.model)
    }
    var body: some View {
        HStack(alignment: .center)
        {
            VStack(alignment: .leading)
            {
                Text("Data Cluster")
                    .font(.title)
                if predictionsDataModel.arrayOfPredictions.count > 0 {
                    List(predictionsDataModel.arrayOfPredictions.sorted(by: { $0.seriesDepth < $1.seriesDepth }), id: \.self, selection: $clusterSelection) { prediction in
                        Text(prediction.groupingPattern!)
                    }
                    HStack {
                        Button("Delete") {
                            clusterSelection = nil
                            predictionsDataModel.deleteAllRecords(predicate: nil)
                            predictionsDataModel.predictions(model: self.model)
                        }
                    }
                }
                else if compositionDataModel.arrayOfClusters.count > 0 {
                    List(compositionDataModel.arrayOfClusters.sorted(by: { $0.seriesDepth < $1.seriesDepth }), id:\.self) { cluster in
                        Text(cluster.groupingPattern!)
                    }
                    Button("Save") {
                            savePredictions()
                    }
                }
            }.frame(width: 240)
            
            VStack(alignment: .leading) {
                if predictionsDataModel.arrayOfPredictions.count > 0 && clusterSelection != nil {
                    Text("Timeseries")
                        .font(.title)
                    List(clusterSelection.timeSeries.sorted(by: { $0.from < $1.from }), id: \.self ) { series in
                        Text("\(series.from) \(series.to)")
                    }
                    Text("Columns")
                        .font(.title)
                    List(clusterSelection.columns.sorted(by: { $0.orderno < $1.orderno }), id:\.self ) { column in
                        Text(column.name!)
                        
                    }
                }
            }
        }
        VStack(alignment: .leading) {
            ValuesView(mlDataTable: (composer?.mlDataTable_Base)!, orderedColumns: (composer?.orderedColumns)!, selectedColumns: selectedColumnCombination, timeSeriesRows: selectedTimeSeriesCombination)
        }.padding(.horizontal)
    }
    func savePredictions() {
        predictionsDataModel.savePredictions(model: self.model)
    }
}
