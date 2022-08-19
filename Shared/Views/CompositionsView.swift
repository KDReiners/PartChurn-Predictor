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
    @State var mlSelection: String? = nil
    var mlAlgorithms = ["MLLinearRegressor", "MLDecisionTreeRegressor", "MLRandomForestRegressor", "MLBoostedTreeRegressor"]
    
    init(model: Models) {
        self.compositionViewModel = CompositionsModel(model: model)
        if compositionViewModel.arrayOfClusters.count == 0 {
            let test = compositionViewModel.hierarchy
        }
    }
        var body: some View {
            List {ForEach(mlSelection, id: \.self, selection: mlSelection!) { cluster in
                VStack
                
            }
        }
    }
}
