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
    @ObservedObject var valuesViewModel = ValuesModel()
    var fileSelection: Files?
    var mlSelection: String?
    var mlAlgorithms = ["MLLinearRegressor", "MLDecisionTreeRegressor", "MLRandomForestRegressor", "MLBoostedTreeRegressor"]
    var mlTable: MLDataTable?
    internal var composer: FileWeaver!
    internal var combinator: Combinator!
    init(model: Models,mlTable: MLDataTable? = nil, modelSelect: NSManagedObject?) {
        self.model = model
        self.mlTable = mlTable
        if modelSelect != nil {
            self.composer = FileWeaver(model: model)
            self.combinator = Combinator(model: self.model, orderedColumns: (composer?.orderedColumns)!, mlDataTable: (composer?.mlDataTable_Base)!)
        }
    }
    var body: some View {
        TabView {
            CompositionsView(model: self.model, composer: self.composer, combinator: self.combinator)
            .tabItem {
                Label("Analysis", systemImage: "tray.and.arrow.down.fill")
            }
            ComposerView(model: model, composer: self.composer, combinator: self.combinator)
            .tabItem {
                Label("Composer", systemImage: "tray.and.arrow.up.fill")
            }
        }
    }
}
