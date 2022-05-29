//
//  ValuesModel.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 06.05.22.
//

import Foundation
import CoreData
import CoreML
import CreateML
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
    internal func getValuesForColumns(columns: Set<Columns>) -> MLDataTable {
        var subEntries = Array<colValTuple>()
        for column in columns {
            for value in column.column2values! {
                let newTuple = colValTuple(column: column, value: value as! Values)
                subEntries.append(newTuple)
            }
        }
        let groupedDictionary = Dictionary(grouping: subEntries, by: { (tuple) -> Columns in
            return tuple.column
        })
        var inputDictionary = [String: MLDataValueConvertible]()
        for (key, values) in groupedDictionary.sorted(by: { $0.key.orderno < $1.key.orderno }){
            var inputArray = [String]()
            for value in values.sorted(by: { $0.value.rowno < $1.value.rowno }) {
                print("Spalte: \(value.column.orderno), Zeile: \(value.value.rowno)")
                inputArray.append(value.value.value! as String)
            }
            inputDictionary[key.name!] = inputArray
            
        }
        return try! MLDataTable(dictionary: inputDictionary)
    }
    internal struct colValTuple {
        var column: Columns
        var value: Values
    }
}

