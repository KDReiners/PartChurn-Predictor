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
    var model: Models
    var valuesViewModel = ValuesModel()
    var mlDataTableProviderContext: SimulationController.MlDataTableProviderContext!
    @ObservedObject var compositionsDataModel = CompositionsModel()
    @ObservedObject var predictionsDataModel = PredictionsModel()
    var fileSelection: Files?
    var mlSelection: String?
    var mlTable: MLDataTable?
    internal var composer: FileWeaver!
    internal var combinator: Combinator!
    init(model: Models, modelSelect: NSManagedObject?) {
        self.model = model
        if modelSelect != nil {
            self.mlDataTableProviderContext = SimulationController.returnFittingProviderContext(model: model, lookAhead: 0)
            self.composer = mlDataTableProviderContext.composer
            self.combinator = mlDataTableProviderContext.combinator
        }
    }
    var body: some View {
        TabView {
            CompositionsView( mlDataTableProviderContext: self.mlDataTableProviderContext)
            .tabItem {
                Label("Analysis", systemImage: "tray.and.arrow.down.fill")
            }
            ComposerView(model: model, composer: self.composer, combinator: self.combinator, compositionsDataModel: compositionsDataModel)
            .tabItem {
                Label("Composer", systemImage: "tray.and.arrow.up.fill")
            }
        }
    }
}
