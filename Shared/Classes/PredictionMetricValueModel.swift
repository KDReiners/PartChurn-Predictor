//
//  PredictionMetricValueModel.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 11.10.22.
//

import Foundation
import Foundation
public class PredictionMetricValueModel: Model<Predictionmetricvalues> {
    @Published var result: [Predictionmetricvalues]!
    public init() {
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
    }
    override public var items: [Predictionmetricvalues] {
        get {
            return result
        }
        set
        {
            result = newValue.sorted(by: { $1.predictionmetricvalue2predictionmetric?.name ?? "" > $0.predictionmetricvalue2predictionmetric?.name ?? ""})
        }
    }
    
}
