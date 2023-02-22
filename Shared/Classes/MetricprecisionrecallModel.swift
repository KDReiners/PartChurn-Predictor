//
//  MetricprecisionrecallModel.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 21.02.23.
//

import Foundation
public class MetricprecisionrecallModell: Model<Metricprecisionrecall> {
    @Published var result: [Metricprecisionrecall]!
    public init() {
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
    }
    override public var items: [Metricprecisionrecall] {
        get {
            return result
        }
        set
        {
            result = newValue
        }
    }
    
}
