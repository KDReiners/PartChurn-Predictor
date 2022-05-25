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
    var baseData: Dictionary<String, Any>?
    init( model: Models, files: [Files] =  [Files]()) {
        self.model = model
        self.files = files
        self.baseData = transform2Dictionary() as Dictionary<String, Any>
    }
    private func transform2Dictionary() -> Dictionary<String, Any?> {
        var result: MLDataTable
        let referredColumns = ColumnsModel().items.filter( { return $0.column2model == model }).sorted(by: {
            $0.orderno < $1.orderno
        })
        var baseData = [String: MLDataValueConvertible]()
        for column in referredColumns.filter( { return $0.isincluded == true}) {
            let sortDescriptor = NSSortDescriptor(key: "rowno", ascending: true)
            let orderedValues = column.column2values?.sortedArray(using: [sortDescriptor]).compactMap({ ($0 as! Values).value })//.map{ Double($0)}
            let typedValues = returnBestType(untypedValues: orderedValues!)
            baseData[column.name!] = typedValues
        }
        result = try! MLDataTable(dictionary: baseData)
        return baseData
    }
    private func returnBestType(untypedValues: [String])  -> MLDataValueConvertible {
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
