//
//  PredictionMetricsModel.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 11.10.22.
//

import Foundation
public class PredictionMetricsModel: Model<Predictionmetrics> {
    @Published var result: [Predictionmetrics]!
    public init() {
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
    }
    override public var items: [Predictionmetrics] {
        get {
            return result
        }
        set
        {
            result = newValue.sorted(by: { $1.name ?? "" > $0.name ?? ""})
        }
    }
}
