//
//  JsonImporter.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 09.08.23.
//

import Foundation
import CreateML
struct JsonImporter {
    var importDictionary: [String: MLDataValueConvertible]
    var model: Models
    var sortedKeys: [String]
    var file: Files?
    var filesDataModel = FilesModel()
    var valuesDataModel = ValuesModel()
    var modelsDataModel = ModelsModel()
    var columnsDataModel = ColumnsModel()
    init(importDictionary: [String : MLDataValueConvertible], selectedModel: Models, fileName: String, sortedKeys: [String]) {
//        modelsDataModel.deleteAllRecords(predicate: nil)
        columnsDataModel.deleteAllRecords(predicate: nil)
//        valuesDataModel.deleteAllRecords(predicate: nil)
        BaseServices.save()
        self.sortedKeys = sortedKeys
        self.importDictionary = importDictionary
        self.model = selectedModel
        file = filesDataModel.items.filter({$0.files2model == selectedModel && $0.name == fileName}).first
        if file == nil {
            file = filesDataModel.insertRecord()
            file?.name = fileName
            self.model.addToModel2files(file!)
        }
        
    }
    func convertToString(_ value: MLDataValueConvertible) -> String? {
        if let intValue = value as? Int {
            return String(intValue)
        } else if let doubleValue = value as? Double {
            return String(doubleValue)
        } else if let stringValue = value as? String {
            return stringValue
        } else {
            return nil
        }
    }
    func getPosionOfColumn(columnName: String) -> Int{
        var result: Int = -99
        for i in 0..<sortedKeys.count {
            if sortedKeys[i] == columnName {
                result = i
            }
        }
        return result
    }
    func saveToCoreData() {
        var colNo: Int = -99
        for entry in importDictionary {
            let newColumn = columnsDataModel.insertRecord()
            newColumn.name = entry.key
            newColumn.column2model = model
            newColumn.column2file = file
            colNo = getPosionOfColumn(columnName: entry.key)
            newColumn.orderno = Int32(colNo)
//            for value in entry.value as! [MLDataValueConvertible] {
//                let newValue = valuesDataModel.insertRecord()
//                newValue.value = convertToString(value)
//                newValue.rowno = Int64(rowNo)
//                newValue.value2model = model
//                newValue.value2file = file
//                newColumn.addToColumn2values(newValue)
//            }
            BaseServices.save()
        }
    }
}
