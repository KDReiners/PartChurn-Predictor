//
//  CoreDataML.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 22.05.22.
//

import Foundation
import CoreML
import CreateML
import SwiftUI
public class CoreDataML: ObservableObject {
    var model: Models?
    var files: Files?
    internal var inputDictionary = [String: MLDataValueConvertible]()
    var columnsModel: ColumnsModel
    internal var mlDataTable: MLDataTable {
        get {
            
            return  getValuesForColumns(columns: Set(self.orderedColumns))
        }
    }
    internal var orderedColumns: [Columns] {
        get {
            return columnsModel.items.filter { return ($0.isincluded == true || $0.isshown == true || $0.istarget == true)  && $0.column2model == self.model && $0.column2file == files}.sorted(by: {
                $0.orderno < $1.orderno
            })
        }
    }
    internal var targetColumns: [Columns] {
        get {
            return columnsModel.items.filter { return $0.isincluded == true && $0.istarget == true && $0.column2model == self.model}.sorted(by: {
                $0.orderno < $1.orderno
            })
        }
    }
    init( model: Models?, files: Files? = Files()) {
        
        self.columnsModel = ColumnsModel(model: model)
        guard let model = model else {
            return
        }
        self.model = model
        guard let files = files else {
            return
        }
        self.files = files
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
        for (key, values) in groupedDictionary.sorted(by: { $0.key.orderno < $1.key.orderno }) {
            let typeOfValues = returnBestType(untypedValues: values)
            var inputArray = [String]()
            for value in values.sorted(by: { $0.value.rowno < $1.value.rowno }) {
                inputArray.append(value.value.value!)
            }
            switch typeOfValues.self {
            case is Int.Type:
                inputDictionary[key.name!] = typedArray<Int>(untypedValues: values).result
            case is Double.Type:
                inputDictionary[key.name!] = typedArray<Double>(untypedValues: values).result
            default:
                inputDictionary[key.name!] = typedArray<String>(untypedValues: values).result
            }
        }
        return try! MLDataTable(dictionary: inputDictionary)
    }
    internal func returnBestType(untypedValues: [colValTuple])  ->  Any {
        let count: Int = untypedValues.count
        let intTemp = untypedValues.map{Int($0.value.value!)}.filter( { return $0 != nil } )
        if intTemp.count > 0 && intTemp.count != count {
            print("Found fuzzy DataType")
        }
        if intTemp.count == count {
            return Int.self
        }
        let doubleTemp = untypedValues.map{ Double($0.value.value!)}.filter( { return $0 != nil})
        if doubleTemp.count ==  count {
            return Double.self
        }
        return String.self
    }
    
    /// Structs
    /// Tuple for column and associated value, Important for ordering
    internal struct colValTuple {
        var column: Columns
        var value: Values
    }
    /// typed array holds the typed columns for mlDataTable
    internal struct typedArray<T> {
        var result: [T]
        var untypedValues: [colValTuple]
        init(untypedValues: [colValTuple]) {
            self.untypedValues = untypedValues
            let orderedValues = untypedValues.sorted(by: { return $0.value.rowno < $1.value.rowno })
            switch T.self {
            case is Int.Type:
                result = orderedValues.map {Int($0.value.value!) as! T}
            case is Double.Type:
                result = orderedValues.map {Double($0.value.value!) as! T}
            default:
                result = orderedValues.map { String($0.value.value!) as! T}
            }
        }

    }
    
}
