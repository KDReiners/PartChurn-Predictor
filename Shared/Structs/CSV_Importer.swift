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
    internal static func read(url: URL, modelName: String) async {
        var columnsArray = Array<Columns>()
        var batchArray = Array<coreDataProperties>()
        let columnsViewModel = ColumnsModel()
        let modelsViewModel = ModelsModel()
        let valuesViewModel = ValuesModel()
        let filesViewModel = FilesModel()
        let model = modelsViewModel.items.first(where: {$0.name == modelName})
        let idModel = model?.objectID.uriRepresentation().absoluteString
        var file = filesViewModel.items.first(where: { $0.files2model == model && $0.name == url.lastPathComponent})
        if file == nil {
            file = filesViewModel.insertRecord()
            file!.name = url.lastPathComponent
            file!.files2model = model
            filesViewModel.saveChanges()
        }
        let idFile = (file?.objectID.uriRepresentation().absoluteString)!
        let stream = InputStream(fileAtPath: url.path)
        let reader = try! CSVReader(stream: stream!, hasHeaderRow: true, delimiter: ";")
        let columns = reader.headerRow!
        
        if !columnsViewModel.items.contains(where: { $0.column2model == model && $0.column2file?.name == url.lastPathComponent }) {
            var i: Int16 = 0
            columns.forEach { column in
                let newColumn = columnsViewModel.insertRecord()
                newColumn.name = column
                newColumn.orderno = i
                i += 1
                newColumn.column2model = model
                newColumn.column2file = file
            }
        }
        columnsArray.append(contentsOf: columnsViewModel.items.filter({ $0.column2file == file}).sorted(by: { $0.orderno < $1.orderno }))
        
        var rowCount: Int64 = 0
        while let row = reader.next() {
            for i in 0..<columns.count {
                let idColumn = columnsArray[i].objectID.uriRepresentation().absoluteString
                let newEntry = coreDataProperties(predictedvalue: "", rowno: rowCount, value: row[i], idmodel: idModel!, idfile: idFile, idcolumn: idColumn)
                batchArray.append(newEntry)
                //                    let newValue = valuesViewModel.insertRecord()
                //                    let col = columnsViewModel.items.first(where: { $0.name == headerRow[i] && $0.column2model == model})
                //                    newValue.value = row[i]
                //                    newValue.value2column = col
                //                    newValue.rowno = rowCount
                //                    newValue.value2model = model
            }
            rowCount += 1
            print(rowCount)
            if rowCount>1000 {
                break
            }
        }
        let batchProvider = BatchProvider()
        _ = try? await batchProvider.importValues(from: batchArray)
//        columnsViewModel.saveChanges()
//        valuesViewModel.saveChanges()
//        modelsViewModel.saveChanges()
//        filesViewModel.saveChanges()
//        valuesViewModel.updateDummyRelations()
    }
    
}

