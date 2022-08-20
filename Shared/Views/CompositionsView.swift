//
//  CompositionsView.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 17.08.22.
//

import SwiftUI

struct CompositionsView: View {
    @ObservedObject var compositionViewModel: CompositionsModel
    var compositionViewDict: Dictionary<String, [CompositionsViewEntry]>?
    @State var clusterSelection: CompositionsModel.Cluster!
    init(model: Models) {
        self.compositionViewModel = CompositionsModel(model: model)
        
        let test = compositionViewModel.hierarchy
        
    }
    var body: some View {
        HStack(alignment: .center)
        {
            VStack(alignment: .leading)
            {
                Text("Data Cluster")
                    .font(.title)
                if compositionViewModel.arrayOfClusters.count > 0 {
                    List(compositionViewModel.arrayOfClusters.sorted(by: { $0.seriesDepth < $1.seriesDepth }), id: \.self, selection: $clusterSelection) { algorithm in
                        Text(algorithm.groupingPattern!)
                    }.frame(width: 250)
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
}
