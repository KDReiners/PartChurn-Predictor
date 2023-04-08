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
    internal func findneighbors(selectedRow: MLDataTable.Row? = nil) {
        var foundRows: [MLDataTable.Row] = []
        let sampleCount = 50
        let maxDistance = 200.00
        var compareTable: MLDataTable?
//        self.targetColumn = columnsDataModel.items.filter( { $0.istarget == 1 && $0.ispartoftimeseries == 1}).first
//        self.targetValue = determineTargetValue()
//        let minorityColumn = self.mlDataTableProvider.mlDataTable![targetColumn!.name!]
//        let majorityColumn = self.mlDataTableProvider.mlDataTableRaw![targetColumn!.name!]
//        let targetMask = minorityColumn == targetValue
//        let othersMask = majorityColumn != targetValue
//        let targetTable = self.mlDataTableProvider.mlDataTable[targetMask]
//        let othersTable = self.mlDataTableProvider.mlDataTableRaw[othersMask]
        guard let selectedRow = selectedRow else { return }
//        for i in 0..<othersTable.rows.count {
//            let distance = euclideanDistance(selectedRow, othersTable.rows[i])
//            print("Distance: \(distance ?? 0)")
//            if distance! <= maxDistance && foundRows.count < sampleCount {
//                foundRows.append(othersTable.rows[i])
//            }
//            if foundRows.count == sampleCount {
//                var dataDict: [String: MLDataValueConvertible] = [:]
//                guard let masterRow = foundRows.first else { break }
//                for key in masterRow.keys {
//                    let valueType = mlDataTableProvider.mlDataTable[key].type
//                    let columnIndex = masterRow.index(forKey: key)
//                    let columnValues = foundRows.compactMap { $0[columnIndex!].1 }
//                    switch valueType {
//                    case .double :
//                        dataDict[key] = columnValues.map { $0.doubleValue!}
//                    case .int:
//                        dataDict[key] = columnValues.map { $0.intValue!}
//                    default:
//                        print("type not found")
//                    }
//                }
//                compareTable = try! MLDataTable(dictionary: dataDict)
//                break
//
//            }
//
//        }
//        guard let compareTable = compareTable else { return }
        getImportances(mldataRowToAnalyze: selectedRow,  prediction: self.mlDataTableProvider.prediction!, compareMLDataTable: compareTable)
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
    private func getImportances(mldataRowToAnalyze: MLDataTable.Row,  prediction: Predictions, compareMLDataTable: MLDataTable? = nil) {
        let mlExplainColumnCluster = MLExplainColumnCluster(prediction: prediction)
        guard let inputColumns = mlExplainColumnCluster.inputColumns else { return }
        guard let targetColumn = mlExplainColumnCluster.targetColumn else { return }
        guard let predictedColumnName = $mlDataTableProvider.valuesTableProvider.wrappedValue?.predictedColumnName! else { return }
        let timeSeriesColumn = mlExplainColumnCluster.timeSeriesColumn
        let primaryKeyColumn = mlExplainColumnCluster.partOfPrimaryKeyColumn
        
        
        let combinator = Combinator(model: mlDataTableProvider.model!, orderedColumns: mlDataTableProvider.orderedColumns, mlDataTable: mlDataTableProvider.mlDataTable)
        var rowDict = self.mlDataTableProvider.valuesTableProvider?.convertRowToDicionary(mlRow: mldataRowToAnalyze)
        guard let baseDict = rowDict else { return }
        
//        guard let transmittedKeys = rowDict?.keys else { return }
//        for key in transmittedKeys {
//            if !inputColumns.map( {$0.name! }).contains(where: { $0.range(of: key.components(separatedBy: "-")[0], options: .caseInsensitive) != nil }) && key != targetColumn.name! && key != timeSeriesColumn?.name! {
//                rowDict!.removeValue(forKey: key)
//            }
//        }
        changeRowDict(rowDict: &rowDict!)
        let basePrediction =  self.mlDataTableProvider.valuesTableProvider?.predict(regressorName: self.mlDataTableProvider.regressorName!, result: rowDict!).featureValue(for: (self.mlDataTableProvider.valuesTableProvider?.targetColumn.name)!)?.doubleValue
        for i in 1...inputColumns.count {
            let combinations = combinator.includedColumnsCombinations(source: Array(inputColumns), takenBy: i)
            guard let simulationBase = constructCombinations(sourceCombinations: combinations, baseRow: mldataRowToAnalyze) else { return }
            for i in 0..<simulationBase.count {
                var inclusionDict = simulationBase[i]
                if  primaryKeyColumn != nil {
                    inclusionDict[(primaryKeyColumn?.name!)!] = baseDict[(primaryKeyColumn?.name!)!]
                }
                if timeSeriesColumn != nil {
                    inclusionDict[(timeSeriesColumn?.name!)!] = baseDict[(timeSeriesColumn?.name!)!]
                }
                inclusionDict[targetColumn.name!] = baseDict[targetColumn.name!]
                inclusionDict[predictedColumnName] = 0.00
                changeRowDict(rowDict: &rowDict!, updateDict: baseDict, inclusionDict: inclusionDict)
                let level = simulationBase[i].keys.count - simulationBase[i].keys.filter({$0.contains("-")}).count
                rowDict!["INPUTCOLUMNS"] = simulationBase[i].keys.sorted( by:  {$0 < $1}).joined(separator: "; ")
                rowDict!["LEVEL"] = level
                let newPrediction =  self.mlDataTableProvider.valuesTableProvider?.predict(regressorName: self.mlDataTableProvider.regressorName!, result: rowDict!).featureValue(for: (self.mlDataTableProvider.valuesTableProvider?.targetColumn.name)!)?.doubleValue
                rowDict![predictedColumnName] = newPrediction
                if mlResultTable == nil {
                    mlResultTable = try? MLDataTable(dictionary: rowDict!)
                }
                else {
                    mlResultTable.append(contentsOf: try! MLDataTable(dictionary: rowDict!))
                }
                
                print ("\(simulationBase[i].keys.joined(separator: ",")); \(newPrediction!)")
                print("ResultTable rows count: \(mlResultTable.rows.count)")
                changeRowDict(rowDict: &rowDict!)
            }
        }
        
        var listOfChanges: [changes] = []


        
        
        
//        for key in compareMLDataTable.columnNames {
//            for row in compareMLDataTable.rows {
//                guard let masterDict = self.mlDataTableProvider.valuesTableProvider?.convertRowToDicionary(mlRow: row) else { continue }
//                let formerValue = rowDict![key]
//                let newValue = masterDict[key]
//                print("existing value for key \(key): \(formerValue!)")
//                print("new value for key \(key): \(newValue!)")
//                rowDict![key] = masterDict[key]
//                let newPrediction = self.mlDataTableProvider.valuesTableProvider?.predict(regressorName: "MLBoostedTreeRegressor", result: rowDict!).featureValue(for: (self.mlDataTableProvider.valuesTableProvider?.targetColumn.name)!)?.doubleValue
//                rowDict![key] = formerValue
//                if newPrediction != basePrediction {
//                   var newChange = changes()
//                    newChange.columnName = key
//                    newChange.formerValue = formerValue
//                    newChange.newValue = newValue
//                    newChange.basePrediction = basePrediction
//                    newChange.newPrediction = newPrediction
//                    newChange.change = newPrediction! - basePrediction!
//                    listOfChanges.append(newChange)
//                }
//            }
//        }

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


