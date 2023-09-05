//
//  ObservationsModel.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 05.09.23.
//

import Foundation
public class ObservationModel: Model<Observations> {
    @Published var result: [Observations]!
    public init() {
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
    }
    override public var items: [Observations] {
        get {
            return result
        }
        set
        {
            result = newValue.sorted(by: { $1.observation2timeslice!.value > $0.observation2timeslice!.value })
        }
    }
    
}
