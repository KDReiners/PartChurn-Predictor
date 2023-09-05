//
//  TimeSliceModel.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 15.08.22.
//

import Foundation
public class TimeSlicesModel: Model<Timeslices> {
    @Published var result: [Timeslices]!
    public init() {
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
    }
    override public var items: [Timeslices] {
        get {
            return result
        }
        set
        {
            result = newValue.sorted(by: { $1.value > $0.value })
        }
    }
    
}
