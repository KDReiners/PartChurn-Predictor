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
            if compositionViewModel.arrayOfClusters.count > 0 {
                List(compositionViewModel.arrayOfClusters, id: \.self, selection: $clusterSelection) { algorithm in
                    Text(algorithm.groupingPattern!)
                }.frame(width: 250)
            }
            if clusterSelection != nil {
                List(clusterSelection.timeSeries, id: \.self ) { series in
                    Text("\(series.from)")
                }
            }
        }
    }
}
