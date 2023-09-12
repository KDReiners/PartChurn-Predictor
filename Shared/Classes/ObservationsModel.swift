//
//  ObservationsModel.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 05.09.23.
//

import Foundation
public class ObservationsModel: Model<Observations> {
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
            result = newValue
        }
    }
    
}
