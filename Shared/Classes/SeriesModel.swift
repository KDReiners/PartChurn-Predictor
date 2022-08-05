//
//  SeriesModel.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 05.08.22.
//
import Foundation
//
//  MetricsModel.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 06.05.22.
//
public class SeriesModel: Model<Series> {
    @Published var result: [Series]!
    public init() {
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
    }
    override public var items: [Series] {
        get {
            return result
        }
        set
        {
            result = newValue.sorted(by: { $1.timeslice > $0.timeslice})
        }
    }
}


