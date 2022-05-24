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
        for column in referredColumns {
            let sortDescriptor = NSSortDescriptor(key: "rowno", ascending: true)
            let orderedValues = column.column2values?.sortedArray(using: [sortDescriptor]).compactMap({ ($0 as! Values).value })//.map{ Double($0)}
            let typedValues = returnBestType(untypedValues: orderedValues!)
            baseData[column.name ?? "test"] = orderedValues
        }
        result = try! MLDataTable(dictionary: baseData)
        return baseData
    }
    private func returnBestType(untypedValues: [String])  -> [Any] {
        let count: Int = untypedValues.count
        let intTemp = untypedValues.map{Int($0)}.filter( { return $0 != nil } )
        if intTemp.count == count {
           return untypedValues.map{Int($0) as Any}
        }
        let doubleTemp = untypedValues.map{ Double($0)}.filter( { return $0 != nil})
        if doubleTemp.count ==  count {
            return untypedValues.map { Double($0) as Any}
        }
        return untypedValues
    }
}
/*
let movieData: [String: MLDataValueConvertible] = [
"Title": ["Titanic", "Shutter Island", "Warriors"],
"Director": ["James Cameron", "Martin Scorsese", "Gavin O'Connor"]
]
var movieTable = try? MLDataTable(dictionary: movieData)
*/
