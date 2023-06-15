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
            let isClassifier = (regressorName?.lowercased().contains("regressor"))! ? false: true
            self.regressorName = regressorName
            self.predistion = prediction
            urlToPredictionModel = BaseServices.createPredictionPath(prediction: prediction!, regressorName: regressorName!)
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: urlToPredictionModel!.path) {
               predictionModel = getModel(url: urlToPredictionModel!)
                incorporatedPrediction(selectedColumns: selectedColumns!, isClassifier: isClassifier)
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
    private func incorporatedPrediction(selectedColumns: [Columns], isClassifier: Bool) {
        let tableDictionary = convertDataTableToDictionary(mlDataTable)
        let provider = try! MLArrayBatchProvider(dictionary: tableDictionary)
        let predictions = try! predictionModel?.predictions(from: provider, options: MLPredictionOptions())
        var predictedValues = [Double]()
        for i in 0..<(predictions?.count ?? 0) {
            predictedValues.append((predictions?.features(at: i).featureValue(for: targetColumn.name!)!.doubleValue)!)
        }
        let newColumn = MLDataColumn(predictedValues)
        mlDataTable.addColumn(newColumn, named: predictedColumnName)
        self.orderedColNames.append(predictedColumnName)
        targetValues[targetColumn.name!] = 0
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
        var sequences: MLDataColumn<CreateML.MLDataValue.SequenceType>?
//        var sequences: MLDataValue
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
        case MLDataValue.ValueType.sequence:
            let packedColumn = mlDataTable[columnName!]
            sequences = packedColumn.map { $0.sequenceValue }
            newCustomColumn.alignment = .leading
            newGridItem = GridItem(.flexible(minimum: 100, maximum: .infinity), spacing: 0, alignment: .leading)
        default:
            print("error determing valueType")
        }
        if rows.count > 0 {
            newCustomColumn.rows.append(contentsOf: rows)
        }
        if sequences != nil {
            newCustomColumn.sequence = sequences
        }
        self.customColumns.append(newCustomColumn)
        self.gridItems.append(newGridItem!)
    }
    func averageValue<T: Sequence>(sequence: T) -> String where T.Element ==  Int {
            var sum: Int = 0
            var count: Int = 0
            
            for element in sequence {
                sum += element
                count += 1
            }
            
            guard count != 0 else {
                return "0"
            }
            
            return String(sum / count)
        }
    func prepareView(orderedColNames: [String]) -> Void {
        var groups: [String: [TimeColumn]] = [:]
        for columnName in orderedColNames {
            let timeSeriesColumnNameRegex = "^(\\w+)-\\d+$"
            let timeSeriesIndexRegex = "\\d+"
            let baseRegexPattern = "[A-Za-z_]+"
            if columnName.range(of: timeSeriesColumnNameRegex, options: .regularExpression) != nil {
                var newTimeColumn = TimeColumn()
                if let range = columnName.range(of: timeSeriesIndexRegex, options: .regularExpression) {
                    newTimeColumn.timeIndex = Int(columnName[range.lowerBound..<range.upperBound])
                }
                if let range = columnName.range(of: baseRegexPattern, options: .regularExpression) {
                    let baseColumnName = String(columnName[range.lowerBound..<range.upperBound])
                    newTimeColumn.baseColumnName = baseColumnName
                    if groups[columnName] == nil {
                        groups[columnName] = []
                    }
                    groups[columnName]?.append(newTimeColumn)
                    if !groups.contains(where: {$0.key == baseColumnName}) {
                        newTimeColumn.timeIndex = 0
                        newTimeColumn.baseColumnName = baseColumnName
                        groups[baseColumnName] = []
                        groups[baseColumnName]?.append(newTimeColumn)
                    }
                }
            }
        }
        let groupArray = groups.map { ($0.key, $0.value) }
        
        let sortingClosure: ((String, [TimeColumn]), (String, [TimeColumn])) -> Bool = { tuple1, tuple2 in
            let baseColumnName1 = tuple1.1.first?.baseColumnName ?? ""
            let baseColumnName2 = tuple2.1.first?.baseColumnName ?? ""
            
            if baseColumnName1 == baseColumnName2 {
                let timeColumns1 = tuple1.1
                let timeColumns2 = tuple2.1

                    let sortedTimeColumns1 = timeColumns1.sorted { $0.timeIndex ?? 0 < $1.timeIndex ?? 0 && $0.baseColumnName == baseColumnName1 }
                    let sortedTimeColumns2 = timeColumns2.sorted { $0.timeIndex ?? 0 < $1.timeIndex ?? 0 && $0.baseColumnName == baseColumnName2 }

                return sortedTimeColumns1.first?.timeIndex ?? 0 < sortedTimeColumns2.first?.timeIndex ?? 0
            } else {
                return baseColumnName1<baseColumnName2
            }
            
        }
        let sortedGroupArray = groupArray.sorted(by: sortingClosure)
        let test = sortedGroupArray.map( {$0.0})
        print(orderedColNames)
        self.gridItems.removeAll()
        for column in orderedColNames {
            if !test.contains(where: { $0 == column }) {
                insertIntoGridItems(column)
            }
        }
        for column in test {
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
    func convertDataTableToDictionary(_ dataTable: MLDataTable) -> [String: [Any]] {
        var dictionary = [String: [Any]]()
        for columnName in dataTable.columnNames {
            let rows = dataTable[columnName]
            switch dataTable[columnName].type {
            case .int:
                dictionary[columnName] = Array(rows.map { $0.intValue })
            case .double:
                dictionary[columnName] = Array(rows.map { $0.doubleValue })
            case .string:
                dictionary[columnName] = Array(rows.map { $0.stringValue })
            default:
                print("ValueType not found")
            }

        }
        return dictionary
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
                let prediction_options = MLPredictionOptions()
                return try predictionModel!.prediction(from: provider, options: prediction_options)
            } catch {
                fatalError(error.localizedDescription)
            }
        }()
        return prediction
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
