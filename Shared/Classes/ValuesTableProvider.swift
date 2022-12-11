//
//  ValuesTableProvider.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 04.07.22.
//

import Foundation
import SwiftUI
import CoreML
import CreateML

class ValuesTableProvider: ObservableObject {
    var coreDataML: CoreDataML!
    var mlDataTable: MLDataTable!
    var models = [model]()
    var urlToPredictionModel: URL?
    var predictionModel: MLModel?
    var customColumns = [CustomColumn]()
    var gridItems = [GridItem]()
    var regressorName: String?
    var predistion: Predictions?
    var orderedColNames: [String]!
    var columnDataModel: ColumnsModel!
    var targetColumn: Columns!
    var predictedColumnName: String!
    var targetValues = [String: Int]()
    var numCols: Int = 0
    var numRows: Int = 0
    init() {
        
    }
    init( mlDataTable: MLDataTable, orderedColNames: [String], selectedColumns: [Columns]?, prediction: Predictions? , regressorName: String?, filter: Bool? = false) {
        self.mlDataTable = mlDataTable
        self.orderedColNames = orderedColNames
        columnDataModel = ColumnsModel(columnsFilter: selectedColumns! )
        targetColumn = columnDataModel.targetColumns.first
        if targetColumn != nil {
            predictedColumnName = "Predicted: " + (targetColumn?.name)!
            removePredictionColumns(predictionColumName: predictedColumnName, filter: filter)
        }
        if regressorName != nil && prediction != nil {
            self.regressorName = regressorName
            self.predistion = prediction
            urlToPredictionModel = BaseServices.createPredictionPath(prediction: prediction!, regressorName: regressorName!)
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: urlToPredictionModel!.path) {
               predictionModel = getModel(url: urlToPredictionModel!)
                incorporatedPredition(selectedColumns: selectedColumns!)
            }
        } else {
           
        }
        prepareView(orderedColNames: self.orderedColNames)
    }
    func removePredictionColumns(predictionColumName: String, filter: Bool? = false) {
        if self.mlDataTable.columnNames.contains(predictedColumnName) && filter != true {
            self.mlDataTable.removeColumn(named: predictedColumnName)
            for i in 0..<orderedColNames.count {
                if orderedColNames[i] == predictedColumnName {
                    self.orderedColNames.remove(at: i)
                }
            }
        }
    }
    init(file: Files?) {
        self.coreDataML = CoreDataML(model: file?.files2model, files: file)
        self.mlDataTable = coreDataML.mlDataTable
        prepareView()
        numCols = customColumns.count
        numRows = numCols > 0 ?customColumns[0].rows.count : 0
    }
    private func incorporatedPredition(selectedColumns: [Columns]) {
        var predictionsDictionary = [String: MLDataValueConvertible]()
        let primaryKeyColumn = columnDataModel.primaryKeyColumn
        let timeStampColumn = columnDataModel.timeStampColumn
        let joinColumns = columnDataModel.joinColumns
        var joinParam1: String = ""
        var joinParam2: String = ""
        var subEntries = Array<PredictionEntry>()
        var joinTable: MLDataTable!
        switch joinColumns.count {
        case 1:
            joinParam1 = Array(joinColumns)[0].name!
        case 2:
            joinParam1 = Array(joinColumns)[0].name!
            joinParam2 = Array(joinColumns)[1].name!
        default: print("no join colums")
        }
        for mlRow in mlDataTable.rows {
            let primaryKeyValue = mlRow[(primaryKeyColumn?.name)!]?.intValue
            targetValues[String((mlRow[ (targetColumn.name!)]?.intValue)!), default: 0] += 1
            let timeStampColumnValue = (mlRow[(timeStampColumn?.name)!]?.intValue)!
            var predictedValue = predictFromRow(regressorName: self.regressorName!, mlRow: mlRow).featureValue(for: targetColumn!.name!)?.doubleValue
            predictedValue = (predictedValue! * 10000).rounded() / 10000
            let newPredictionEntry = PredictionEntry(primaryKey: primaryKeyValue!, timeSeriesValue: timeStampColumnValue, predictedValue: predictedValue!)
            subEntries.append(newPredictionEntry)
        }
        predictionsDictionary[primaryKeyColumn!.name!] = subEntries.map({ $0.primaryKey})
        predictionsDictionary[timeStampColumn!.name!] = subEntries.map({ $0.timeSeriesValue})
        predictionsDictionary[predictedColumnName] = subEntries.map({ $0.predictedValue})
        joinTable = try? MLDataTable(dictionary: predictionsDictionary)
        switch joinColumns.count {
        case 1:
            mlDataTable = mlDataTable.join(with: joinTable, on: joinParam1)
        case 2:
            mlDataTable = mlDataTable.join(with: joinTable, on: joinParam1, joinParam2, type: .inner)
        default: print("no join columns")
        }
        self.orderedColNames.append(predictedColumnName)
    }
    struct PredictionEntry: Hashable {
        var primaryKey: Int
        var timeSeriesValue: Int
        var predictedValue: Double
        var combinedKey: String {
            get {
                return String(primaryKey) + "_" + String(timeSeriesValue)
            }
        }
    }
    
    func insertIntoGridItems(_ columnName: String?) {
        var rows = [String]()
        var newCustomColumn = CustomColumn(title: columnName!, alignment: .trailing)
        var newGridItem: GridItem?
        let valueType = mlDataTable[columnName!].type
        let mlDataValueFormatter = NumberFormatter()
        switch valueType {
        case MLDataValue.ValueType.int:
            rows = Array.init(mlDataTable[columnName!].map( { mlDataValueFormatter.string(from: NSNumber(value: $0.intValue!)) }))
            newCustomColumn.alignment = .trailing
            newGridItem = GridItem(.flexible(minimum: 100, maximum: .infinity), spacing: 0, alignment: .trailing)
        case MLDataValue.ValueType.double:
            mlDataValueFormatter.minimumFractionDigits = 4
            mlDataValueFormatter.maximumFractionDigits = 4
            mlDataValueFormatter.hasThousandSeparators = true
            rows = Array.init(mlDataTable[columnName!].map( { mlDataValueFormatter.string(from: NSNumber(value: $0.doubleValue!)) }))
            newCustomColumn.alignment = .trailing
            newGridItem = GridItem(.flexible(minimum: 100, maximum: .infinity), spacing: 0, alignment: .trailing)
        case MLDataValue.ValueType.string:
            rows = Array.init(mlDataTable[columnName!].map( { $0.stringValue! }))
            newCustomColumn.alignment = .leading
            newGridItem = GridItem(.flexible(minimum: 100, maximum: .infinity), spacing: 0, alignment: .leading)
        default:
            print("error determing valueType")
        }
        newCustomColumn.rows.append(contentsOf: rows)
        self.customColumns.append(newCustomColumn)
        self.gridItems.append(newGridItem!)
    }
    
    func prepareView(orderedColNames: [String]) -> Void {
        self.gridItems.removeAll()
        for column in orderedColNames {
            insertIntoGridItems(column)
        }
    }
    func prepareView() -> Void {
        var rows = [String]()
        for column in self.coreDataML.orderedColumns {
            if column.isshown! == 1 {
                var newCustomColumn = CustomColumn(title: column.name ?? "Unbekannt", alignment: .trailing)
                var newGridItem: GridItem?
                let valueType = mlDataTable[column.name!].type
                let mlDataValueFormatter = NumberFormatter()
                mlDataValueFormatter.numberStyle = column.decimalpoint == true ? .decimal : .none
                switch valueType {
                case MLDataValue.ValueType.int:
                    mlDataValueFormatter.minimumFractionDigits = 0
                    rows = Array.init(mlDataTable[column.name!].map( { mlDataValueFormatter.string(from: NSNumber(value: $0.intValue!)) }))
                    newCustomColumn.alignment = .trailing
                    newGridItem = GridItem(.flexible(), spacing: 10, alignment: .trailing)
                    column.datatype = BaseServices.columnDataTypes.Int.rawValue
                case MLDataValue.ValueType.double:
                    mlDataValueFormatter.minimumFractionDigits = 2
                    mlDataValueFormatter.maximumFractionDigits = 2
                    rows = Array.init(mlDataTable[column.name!].map( { mlDataValueFormatter.string(from: NSNumber(value: $0.doubleValue!)) }))
                    newCustomColumn.alignment = .trailing
                    newGridItem = GridItem(.flexible(),spacing: 10, alignment: .trailing)
                    column.datatype = BaseServices.columnDataTypes.Double.rawValue
                case MLDataValue.ValueType.string:
                    rows = Array.init(mlDataTable[column.name!].map( { $0.stringValue! }))
                    newCustomColumn.alignment = .leading
                    newGridItem = GridItem(.flexible(),spacing: 10, alignment: .leading)
                    column.datatype = BaseServices.columnDataTypes.String.rawValue
                default:
                    print("error determining value type")
                }
                newCustomColumn.rows.append(contentsOf: rows)
                newGridItem = GridItem(.flexible(), spacing: 10, alignment: .trailing)
                self.customColumns.append(newCustomColumn)
                self.gridItems.append(newGridItem!)
            }
        }
    }
    private func getModel(url: URL) ->MLModel {
        var result: MLModel?
        if let result = models.filter({ $0.url == url}).first?.model {
            return result
        } else {
            let compiledUrl:URL = {
                do {
                    return try MLModel.compileModel(at: url)
                } catch {
                    fatalError(error.localizedDescription)
                }
            }()
            result = {
                do {
                    return try MLModel(contentsOf: compiledUrl)
                } catch {
                    fatalError(error.localizedDescription)
                }
            }()
            
        }
        let newModel = model(model: result!, url: url)
        models.append(newModel)
        return result!
    }
    func predict(regressorName: String, result: [String : MLDataValueConvertible]) -> MLFeatureProvider {
        let provider: MLDictionaryFeatureProvider = {
            do {
                return try MLDictionaryFeatureProvider(dictionary: result)
            } catch {
                fatalError(error.localizedDescription)
            }
        }()
        let prediction: MLFeatureProvider = {
            do {
                return try predictionModel!.prediction(from: provider)
            } catch {
                fatalError(error.localizedDescription)
            }
        }()
        return prediction
    }
    public func predictFromRow(regressorName: String, mlRow: MLDataTable.Row) -> MLFeatureProvider {
        var result = [String: MLDataValueConvertible]()
        for i in 0..<mlRow.keys.count {
            if mlRow.keys[i] != "ALIVE" {
                result[mlRow.keys[i]] = mlRow.values[i].intValue
                if  result[mlRow.keys[i]] == nil {
                    result[mlRow.keys[i]] = mlRow.values[i].doubleValue
                }
                if  result[mlRow.keys[i]] == nil {
                    result[mlRow.keys[i]] = mlRow.values[i].stringValue
                }
            }
        }
        return predict(regressorName: regressorName, result: result)
    }
    internal func convertRowToDicionary(mlRow: MLDataTable.Row) -> [String: MLDataValueConvertible] {
        var result = [String: MLDataValueConvertible]()
        for i in 0..<mlRow.keys.count {
            result[mlRow.keys[i]] = mlRow.values[i].intValue
            if  result[mlRow.keys[i]] == nil {
                result[mlRow.keys[i]] = mlRow.values[i].doubleValue
            }
            if  result[mlRow.keys[i]] == nil {
                result[mlRow.keys[i]] = mlRow.values[i].stringValue
            }
        }
        return result
    }
    struct model: Identifiable {
        let id = UUID()
        var model: MLModel
        var path: String?
        var url: URL
    }
}
