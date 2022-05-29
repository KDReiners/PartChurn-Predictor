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
public class coreDataDictionary: ObservableObject {
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
//        self.baseData = transform2Dictionary() as Dictionary<String, [String]>
    }
    private func getBaseData() -> MLDataTable {
        var result = MLDataTable()
        let includedColumns = ColumnsModel().items.filter { return $0.isincluded == true}.sorted(by: {
            $0.orderno < $1.orderno
        })
        result = ValuesModel().getValuesForColumns(columns: Set(includedColumns))
        let test = try! MLRegressor(trainingData: result, targetColumn: "Kuendigt")
        return result
    }
    private func transform2Dictionary() -> Dictionary<String, [String]> {

        let referredColumns = ColumnsModel().items.filter( { return $0.column2model == model }).sorted(by: {
            $0.orderno < $1.orderno
        })
        var baseData =  Dictionary<String, [String]>()
        for column in referredColumns.filter( { return $0.isincluded == true}) {
            let sortDescriptor = NSSortDescriptor(key: "rowno", ascending: true)
            let orderedValues = column.column2values?.sortedArray(using: [sortDescriptor]).compactMap({ ($0 as! Values).value })//.map{ Double($0)}
            let typedValues = returnBestType(untypedValues: orderedValues!)
            baseData[column.name!] = orderedValues
        }
        return baseData
    }
    internal func returnBestType(untypedValues: [String])  -> MLDataValueConvertible {
        let count: Int = untypedValues.count
        let intTemp = untypedValues.map{Int($0)}.filter( { return $0 != nil } )
        if intTemp.count == count {
            return untypedValues.map{Int($0)! as Int}
        }
        let doubleTemp = untypedValues.map{ Double($0)}.filter( { return $0 != nil})
        if doubleTemp.count ==  count {
            return untypedValues.map { Double($0)! as Double}
        }
        return untypedValues
    }
}
