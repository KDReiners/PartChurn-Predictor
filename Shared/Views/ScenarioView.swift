//
//  ScenarioView.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 08.07.22.
//

import SwiftUI
import CreateML

struct ScenarioView: View {
    /// for modelsView
    @ObservedObject var model: Models
    @ObservedObject var metric: Ml_MetricKPI
    @ObservedObject var valuesViewModel = ValuesModel()
    var fileSelection: Files?
    var mlSelection: String?
    var mlAlgorithms = ["MLLinearRegressor", "MLDecisionTreeRegressor", "MLRandomForestRegressor", "MLBoostedTreeRegressor"]
    var mlTable: MLDataTable?
    var body: some View {
        TabView {
            ModelsView(model: model, metric: metric, valueViewModel: valuesViewModel, mlSelection: mlSelection, mlAlgorithms: mlAlgorithms, mlTable: mlTable)
            .tabItem {
                Label("Analysis", systemImage: "tray.and.arrow.down.fill")
            }
            ComposerView(model: model)
            .tabItem {
                Label("Composer", systemImage: "tray.and.arrow.up.fill")
            }
        }
    }
}

struct ScenarioView_Previews: PreviewProvider {
    static var previews: some View {
        ScenarioView(model: ModelsModel().items[0], metric: Ml_MetricKPI(), mlTable: CoreDataML(model: ModelsModel().items[0]).mlDataTable)
    }
}
