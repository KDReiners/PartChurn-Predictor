//
//  CSV_Importer.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 06.05.22.
//

import Foundation
import CSV
import SwiftUI

struct CSV_Importer {
    internal static func read(url: URL, modelName: String) {
        let columnsViewModel = ColumnsModel()
        let modelsViewModel = ModelsModel()
        let valuesViewModel = ValuesModel()
        let filesViewModel = FilesModel()
        let model = modelsViewModel.items.first(where: {$0.name == modelName})
        let file = filesViewModel.items.first(where: { $0.files2model == model && $0.name == url.lastPathComponent})
        let stream = InputStream(fileAtPath: url.path)
        let reader = try! CSVReader(stream: stream!, hasHeaderRow: true, delimiter: ";")
        let headerRow = reader.headerRow!
        if !columnsViewModel.items.contains(where: { $0.column2model == model}) {
            var i: Int16 = 0
            headerRow.forEach { column in
                let newColumn = columnsViewModel.insertRecord()
                newColumn.name = column
                newColumn.orderno = i
                i += 1
                newColumn.column2model = model
            }
        }
        if file == nil {
            let newFile = filesViewModel.insertRecord()
            newFile.name = url.lastPathComponent
            newFile.files2model = model
            var rowCount: Int64 = 0
            while let row = reader.next() {
                for i in 0..<headerRow.count {
                    let newValue = valuesViewModel.insertRecord()
                    let col = columnsViewModel.items.first(where: { $0.name == headerRow[i] && $0.column2model == model})
                    newValue.value = row[i]
                    newValue.value2column = col
                    newValue.rowno = rowCount
                    newValue.value2model = model
                }
                rowCount += 1
            }
        }
        columnsViewModel.saveChanges()
        valuesViewModel.saveChanges()
        modelsViewModel.saveChanges()
    }
}
