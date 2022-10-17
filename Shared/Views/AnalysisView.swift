//
//  AnalysisView.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 16.10.22.
//

import SwiftUI

struct AnalysisView: View {
    var analysisProvider: AnalysisProvider
    init(model: Models) {
        self.analysisProvider = AnalysisProvider(model: model)
        PredictionMetricsModel().deleteAllRecords(predicate: nil)
        PredictionMetricValueModel().deleteAllRecords(predicate: nil)
    }
    var body: some View {
        Button("Explode") {
            self.analysisProvider.explode()
        }
    }
}

struct AnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        AnalysisView(model: ModelsModel().items.first!)
    }
}
