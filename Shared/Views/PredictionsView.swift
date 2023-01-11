//
//  PredictionsView.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 17.01.23.
//

import SwiftUI

struct PredictionsView: View {
    var model: Models
    var predictionsModel = PredictionsModel()
    init(model: Models) {
        self.model = model
        var predictions = predictionsModel.convertToJSONArray(moArray: MetricsModel().items)
        
    }
    var body: some View {
        Text("Hallo")
    }
        
}

struct PredictionsView_Previews: PreviewProvider {
    static var previews: some View {
        PredictionsView(model: ModelsModel().items.first!)
    }
}
