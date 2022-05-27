//
//  ValuesModel.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 06.05.22.
//

import Foundation
import CoreData
public class ValuesModel: Model<Values> {
    @Published var result: [Values]!
    public init() {
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
    }
    override public var items: [Values] {
        get {
            return result
        }
        set
        {
            result = newValue
        }
    }
    public func recordCount(model: Models) -> Int {
        let lastValue = (model.model2values?.allObjects as? [Values])!.max(by: {(value1, value2)-> Bool in
            return value1.rowno < value2.rowno
        } )
        guard let lastValue = lastValue else {
            return 0
        }
        return Int(lastValue.rowno)
    }
    public func getValuesForColumns(columns: Set<Columns>) -> Dictionary<String, [colValTuple]> {
        var subEntries = Array<colValTuple>()
        for column in columns {
            for value in column.column2values! {
                let newTuple = colValTuple(column: column, value: value as! Values)
                subEntries.append(newTuple)
            }
        }
        let result = Dictionary(grouping: subEntries, by: { (tuple) -> String in
            return tuple.column.name!
        })
        return result
    }
    public struct colValTuple {
        var column: Columns
        var value: Values
    }
}

