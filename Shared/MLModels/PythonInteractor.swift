//
//  PythonInteraction.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 05.03.23.
//

import Foundation
import PythonKit
import CoreML
import CreateML
import SwiftUI

class PythonInteractor {
    @ObservedObject var mlDataTableProvider: MlDataTableProvider
    var columnsDataModel: ColumnsModel!
    var targetColumn: Columns!
    var targetValue: Int!
    var mlResultTable: MLDataTable!
    init(mlDataTableProvider: MlDataTableProvider) {
        self.mlDataTableProvider = mlDataTableProvider
        self.columnsDataModel = ColumnsModel(model: mlDataTableProvider.model)
    }
    private func determineTargetValue() -> Int? {
        var result: Int?
        var agg = [MLDataTable.Aggregator]()
        agg.append(MLDataTable.Aggregator.init(operations: .count, of: targetColumn.name!))
        let groupedTable = mlDataTableProvider.mlDataTable.group(columnsNamed: self.targetColumn.name!, aggregators: agg)
        let values = groupedTable[self.targetColumn.name!].map { $0.intValue }
        if let minCount = values.min() {
            result = minCount
        } else {
            print("table is empty.")
        }
        return result
    }
    private func constructCombinations(sourceCombinations: [[Columns]], baseRow: MLDataTable.Row) -> Array<Dictionary<String, Any>>! {
        var result = [[String: Any]]()
        for i in 0..<sourceCombinations.count {
            var newDict: Dictionary<String, Any> = [:]
            for columnName in sourceCombinations[i].map({ $0.name!}) {
                newDict[columnName] = 0 // whatever value, but a value needs to be set
                let predicate = NSPredicate(format: "SELF LIKE[c] %@ AND SELF != %@", "\(columnName)*", columnName)
                let dependantNames = baseRow.keys.filter { predicate.evaluate(with: $0) }
                for dependantColumnName in dependantNames {
                    newDict[dependantColumnName] = 0 // whatever value, but a value needs to be set
                }
            }
            result.append(newDict)
        }
        return result
    }
    
    struct changes {
        var columnName: String!
        var formerValue: Any!
        var newValue: Any!
        var basePrediction: Any!
        var newPrediction: Any!
        var change: Double!
    }
    
    func changeRowDict(rowDict: inout [String: MLDataValueConvertible], updateDict:  [String: MLDataValueConvertible]? = nil, inclusionDict: Dictionary<String, Any>? = nil) {
        for key in rowDict.keys {
            let valueType = rowDict[key]?.dataValue.type
            switch valueType {
            case .int:
                rowDict[key] = inclusionDict?[key] == nil ? 0 :updateDict![key]
            case .double:
                rowDict[key] = inclusionDict?[key] == nil ? 0.0 :updateDict![key]
            case .string:
                rowDict[key] = inclusionDict?[key] == nil ? "" :updateDict![key]
            default:
                print("ValueType not found")
            }
        }
        
    }
    func euclideanDistance(_ row1: MLDataTable.Row, _ row2: MLDataTable.Row) -> Double? {
        // Ensure the two rows have the same number of columns
        guard row1.count == row2.count else { return nil }
        var value1: Double!
        var value2: Double!
        var distance = 0.0
        for key in row1.keys {
            let column = columnsDataModel.items.first(where: {$0.name == key })
            if column != nil {
                if column!.isshown == false || column!.istimeseries == true || column!.ispartofprimarykey == true {
                continue
            }
        }
            let valueType = row1[key]!.type
            switch valueType {
            case .int:
                value1 = Double((row1[key]?.intValue)!)
                value2 = Double((row2[key]?.intValue)!)
            case .double:
                value1 = row1[key]?.doubleValue
                value2 = row2[key]?.doubleValue
            default:
                print("value type not found!")
            }
            
            distance += pow(value1 - value2, 2)
        }
        
        // Return the square root of the sum of squared differences
        return sqrt(distance)
    }
}


