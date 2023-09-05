//
//  TimeSeriesModel.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 15.08.22.
//

import Foundation
public class TimeSeriesModel: Model<Timeseries> {
    @Published var result: [Timeseries]!
    public init() {
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
    }
    override public var items: [Timeseries] {
        get {
            return result
        }
        set
        {
            result = newValue.sorted(by: { $1.from > $0.to })
        }
    }
}
