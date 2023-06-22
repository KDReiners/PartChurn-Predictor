//
//  CompositionView.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 06.11.22.
//

import SwiftUI
struct SimulatorView: View {
    @EnvironmentObject var mlSimulationController: SimulationController
    var mlDataTableProviderContext: SimulationController.MlDataTableProviderContext!
    var predictionsDataModel = PredictionsModel()
    var prediction: Predictions?
    var model: Models?
    @State var valuesView: ValuesView?
    init(prediction: Predictions?, algorithmName: String) {
        guard let prediction = prediction else {
            return
        }
        self.prediction = prediction
        guard let model = prediction.prediction2model else {
            fatalError("No model connected to prediction.")
        }
        guard let mlDataTableProviderContext = SimulationController.returnFittingProviderContext(model: model, lookAhead: 0, prediction: prediction) else {
            fatalError("No mlDataTableProviderContext created")
        }
        self.model = model
        self.mlDataTableProviderContext = mlDataTableProviderContext 
        self.mlDataTableProviderContext.setPrediction(prediction: prediction)
        
        valuesView = ValuesView(mlDataTableProvider: mlDataTableProviderContext.mlDataTableProvider)
        self.mlDataTableProviderContext.createGridItems()
    }
    
    var body: some View {
        VStack(alignment: .center) {
            PredictionView(mlDataTableProviderContext: self.mlDataTableProviderContext)
            Divider()
            ValuesView(mlDataTableProvider: self.mlDataTableProviderContext.mlDataTableProvider)
        }.background(.white)
    }
}
