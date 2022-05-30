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
    var model: Models
    var files: [Files]
    internal var baseData: MLDataTable {
        get {
            return  getBaseData()
        }
    }
    init( model: Models, files: [Files] =  [Files]()) {
        self.model = model
        self.files = files
    }
    private func getBaseData() -> MLDataTable {
        var result = MLDataTable()
        let includedColumns = ColumnsModel().items.filter { return $0.isincluded == true}.sorted(by: {
            $0.orderno < $1.orderno
        })
        result = getValuesForColumns(columns: Set(includedColumns))
        do {
            var test = try? MLRegressor(trainingData: result, targetColumn: "Kuendigt")
        } catch {
            print(error)
        }
        return result
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
            let arrayType = returnBestType(untypedValues: values)
            var inputArrayOfStrings = [String]()
            var inputArrayOfInts = [Int]()
            var inputArrayOfDoubles = [Double]()
            for value in values.sorted(by: { $0.value.rowno < $1.value.rowno }) {
                switch arrayType {
                case 0:
                    inputArrayOfInts.append(Int(value.value.value!)!)
                case 1:
                    inputArrayOfDoubles.append(Double(value.value.value!)!)
                default:
                    inputArrayOfStrings.append(value.value.value!)
                }
            }
            switch arrayType {
            case 0:
                inputDictionary[key.name!] = inputArrayOfInts
            case 1:
                inputDictionary[key.name!] = inputArrayOfDoubles
            default:
                inputDictionary[key.name!] = inputArrayOfStrings
            }
            
        }
        return try! MLDataTable(dictionary: inputDictionary)
    }
    internal struct colValTuple {
        var column: Columns
        var value: Values
    }
    internal func returnBestType(untypedValues: [colValTuple])  ->  Int {
        let count: Int = untypedValues.count
        let intTemp = untypedValues.map{Int($0.value.value!)}.filter( { return $0 != nil } )
        if intTemp.count == count {
            return 0
        }
        let doubleTemp = untypedValues.map{ Double($0.value.value!)}.filter( { return $0 != nil})
        if doubleTemp.count ==  count {
            return 1
        }
        return 2
    }
}
