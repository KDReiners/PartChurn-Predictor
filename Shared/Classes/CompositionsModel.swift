//
//  CompositionsModel.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 24.07.22.
//

import Foundation
public class CompositionModel: Model<Compositions> {
    @Published var result: [Compositions]!
    public init() {
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
    }
    override public var items: [Compositions] {
        get {
            return result
        }
        set
        {
            result = newValue.sorted(by: { $1.orderno > $0.orderno })
        }
    }
    
}
