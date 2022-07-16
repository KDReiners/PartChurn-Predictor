//
//  Composer.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 10.07.22.
//

import Foundation
import CoreData
import CoreML
import CreateML

internal class Composer {
    var model: Models
    var files: NSSet!
    var mlDataTable_Base: MLDataTable!
    var columnsDataModel = ColumnsModel()
    var orderedColumns = [Columns]()
    static var valuesDataModel = ValuesModel()
    var cognitionSources = [CognitionSource]()
    var cognitionObjects = [CognitionObject]()
    init(model: Models)
    {
        self.model = model
        self.files = model.model2files
        examine()
        self.mlDataTable_Base = compose()
    }
    private func examine() -> Void {
        for file in files {
            let columns = columnsDataModel.items.filter { $0.column2file == file as? Files }.sorted(by: { $0.orderno < $1.orderno })
            let newCognitionSource = CognitionSource(columns: columns)
            if newCognitionSource.name != nil {
                cognitionSources.append(newCognitionSource)
            }
            let newCognitionObject = CognitionObject( columns: columns)
            if newCognitionObject.name != nil {
                cognitionObjects.append(newCognitionObject)
            }
        }
    }
    private func compose() -> MLDataTable {
        var allInDataTable = MLDataTable()
        for cognitionSource in cognitionSources {
            let transformedTable: MLDataTable = adjustColumnNames(cognitionSource: cognitionSource)
            if allInDataTable.rows.count == 0 {
                allInDataTable = transformedTable
            } else {
                allInDataTable = allInDataTable.join(with: transformedTable, on: "S_CUSTNO")
            }
        }
        for cognitionObject in cognitionObjects {
            let transformedTable: MLDataTable = adjustColumnNames(cognitionObject: cognitionObject)
            allInDataTable = allInDataTable.join(with: transformedTable, on: "S_CUSTNO")
        }
        return allInDataTable
    }
    private func adjustColumnNames(cognitionSource: CognitionSource) -> MLDataTable{
        let prefix = cognitionSource.name
        var mlDataTable_Adjusted = cognitionSource.coreDataML?.mlDataTable
        for column in cognitionSource.coreDataML!.orderedColumns {
            let columnName = column.name!
            column.alias = column.name!
            let pattern = String(column.ispartofprimarykey == true ? 1: 0) + String(column.isincluded == true ? 1: 0) + String(column.isshown == true ? 1: 0)
            if columnName != "COGNITIONSOURCE" && column.isincluded == true {
                let alias = prefix! +  "\n" + columnName
                mlDataTable_Adjusted?.renameColumn(named: columnName, to: alias)
                column.alias = alias
                self.orderedColumns.append(column)
            } else if columnName != "COGNITIONSOURCE" && column.isincluded == false && column.isshown == true {
                self.orderedColumns.append(column)
            } else {
                mlDataTable_Adjusted?.removeColumn(named: "COGNITIONSOURCE")
            }
        }
        return mlDataTable_Adjusted!
    }
    private func adjustColumnNames(cognitionObject: CognitionObject) -> MLDataTable{
        let prefix = cognitionObject.name
        var mlDataTable_Adjusted = cognitionObject.coreDataML?.mlDataTable
        for column in cognitionObject.coreDataML!.orderedColumns {
            let columnName = column.name!
            column.alias = column.name!
            if columnName != "COGNITIONOBJECT" && column.istarget == true && column.ispartofprimarykey == false {
                let alias = prefix! +  "\n" + columnName
                mlDataTable_Adjusted?.renameColumn(named: columnName, to: alias)
                column.alias = alias
                self.orderedColumns.append(column)
            } else if columnName != "COGNITIONOBJECT" && column.istarget == false && column.ispartofprimarykey == true {
                self.orderedColumns.append(column)
            } else if columnName != "COGNITIONOBJECT" && column.ispartofprimarykey == true {
                column.isshown = false
            }
            else {
                mlDataTable_Adjusted?.removeColumn(named: "COGNITIONOBJECT")
            }
        }
        return mlDataTable_Adjusted!
    }
    static func getColumnPivotValue(pivotColum: Columns?) ->String? {
        return Composer.valuesDataModel.items.filter { $0.value2column == pivotColum}.first?.value
    }
    internal struct CognitionSource: Identifiable {
        var id = UUID()
        var name: String!
        var file: Files!
        var columns: [Columns]
        var valueColumns: [Columns]
        var coreDataML: CoreDataML?
        init(columns: [Columns]) {
            self.file = columns.first?.column2file
            self.columns = columns
            let coginitionSourceColumn = columns.filter { return $0.name == "COGNITIONSOURCE"}.first
            self.name = getColumnPivotValue(pivotColum: coginitionSourceColumn)
            self.valueColumns = columns.filter { return $0.name != "COGNITIONSOURCE" }
            if self.name != nil {
                coreDataML = CoreDataML(model: file.files2model, files: file)
            }
        }
    }
    internal struct CognitionObject: Identifiable {
        var id = UUID()
        var name: String!
        var file: Files!
        var columns: [Columns]
        var valueColumns: [Columns]
        var coreDataML: CoreDataML?
        init(columns: [Columns]) {
            self.file = columns.first?.column2file
            self.columns = columns
            let cognitionObjectColumn = columns.filter { return $0.name == "COGNITIONOBJECT"}.first
            self.name = getColumnPivotValue(pivotColum: cognitionObjectColumn)
            self.valueColumns = columns.filter { return $0.name != "COGNITIONOBJECT" }
            if self.name != nil {
                coreDataML = CoreDataML(model: file.files2model, files: file)
            }
            
        }
    }
}

