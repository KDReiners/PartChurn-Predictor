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
    struct LookAheadItemRelations {
        var lookAheadItem: Lookaheads
        var connectedAlgorihms: [Algorithms] {
            get {
                var returnValue: [Algorithms] = []
                let predictionMetricValues = (lookAheadItem.lookahead2predictionmetricvalue?.allObjects) as! [Predictionmetricvalues]
                for predictionMetricValue in predictionMetricValues.filter( { $0.predictionmetricvalue2lookahead == lookAheadItem} ) {
                    returnValue.append(predictionMetricValue.predictionmetricvalue2algorithm!)
                }
                return returnValue
            }
        }
        
    }
}
