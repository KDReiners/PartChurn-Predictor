//
//  MetricvaluesModel.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 14.05.22.
//

import Foundation
public class MetricvaluesModel: Model<Metricvalues> {
    @Published var result: [Metricvalues]!
    public init() {
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
    }
    override public var items: [Metricvalues] {
        get {
            return result
        }
        set
        {
            result = newValue.sorted(by: { $1.metricvalue2metric?.name ?? "" > $0.metricvalue2metric?.name ?? ""})
        }
    }
    
}
