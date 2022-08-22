//
//  CompositionsView.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 17.08.22.
//

import SwiftUI

struct CompositionsView: View {
    @ObservedObject var compositionViewModel: CompositionsModel
    var predictionsDataModel = PredictionsModel()
    var compositionViewDict: Dictionary<String, [CompositionsViewEntry]>?
    var model: Models
    @State var clusterSelection: PredictionsModel.prediction!
    init(model: Models) {
        self.model = model
        self.compositionViewModel = CompositionsModel(model: self.model)
        compositionViewModel.presentCalculationTasks()
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
                    List(predictionsDataModel.arrayOfPredictions, id: \.self, selection: $clusterSelection) { algorithm in
                        Text(algorithm.groupingPattern!)
                    }.frame(width: 279)
                    HStack {
                        Button("Delete") {
                            predictionsDataModel.deleteAllRecords(predicate: nil)
                        }
                        Button("Save") {
                            savePredictions()
                        }
                    }
                }
            }
            VStack(alignment: .leading) {
                if clusterSelection != nil {
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
    }
    func savePredictions() {
        predictionsDataModel.savePredictions(model: self.model)
    }
}
