//
//  CategoriesModel.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 01.03.23.
//

import Foundation
import CoreData
import SwiftUI
public class LookaheadsModel: Model<Lookaheads> {
    @Published var result: [Lookaheads]!
    public init() {
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
    }
    override public var items: [Lookaheads] {
        get {
            return result
        }
        set
        {
            result = newValue
        }
    }
}
