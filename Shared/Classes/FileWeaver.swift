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
import SwiftUI

internal class FileWeaver {
    var model: Models
    var files: NSSet!
    var mlDataTable_Base: MLDataTable!
    var columnsDataModel = ColumnsModel()
    var allColumns: [Columns]
    var orderedColumns: [Columns]!
    var timeBasedColumns: [String]
    var primaryKeyColumns: [String]
    var allInDataTable = MLDataTable()
    
    static var valuesDataModel = ValuesModel()
    var cognitionSources = [CognitionSource]()
    var cognitionObjects = [CognitionObject]()
    init(model: Models)
    {
        self.allColumns = Array(model.model2columns?.allObjects as! [Columns]).sorted(by: { $0.orderno < $1.orderno})
        self.model = model
        self.files = model.model2files
        self.timeBasedColumns = Array(model.model2columns?.allObjects as! [Columns]).filter({ $0.istimeseries == 1 }).map( {
            $0.name!
        })
        self.primaryKeyColumns = Array(model.model2columns?.allObjects as! [Columns]).filter({ $0.ispartofprimarykey == 1 }).map( {
            $0.name!
        })
        examine()
        self.mlDataTable_Base = compose()
    }
    private func orderColumns(allColumns: [Columns]) -> [Columns] {
        var result = [Columns]()
        var i = -1
        for column in allColumns {
            for mlDataColumnName in allInDataTable.columnNames {
                if mlDataColumnName == column.name && !result.contains(where: { $0.name == mlDataColumnName}) {
                    i += 1
                    column.orderno = Int16(i)
                    result.append(column)
                }
            }
        }
        let targetColumn = allColumns.first(where:  {$0.istarget == 1})
        targetColumn?.orderno = Int16(result.count + 1)
        BaseServices.save()
        return result
        
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
        var joinParam1: String = ""
        var joinParam2: String = ""
        
        for cognitionSource in cognitionSources {
            guard let currentMLDataTable = cognitionSource.coreDataML?.mlDataTable else {
                fatalError("no mldatatable found in cognition source.")
            }
            if allInDataTable.rows.count == 0 {
                allInDataTable = currentMLDataTable
            } else {
                let joinColumns = Set(allInDataTable.columnNames).intersection(currentMLDataTable.columnNames)
//                joinColumns.remove(at: joinColumns.firstIndex(of: "COGNITIONSOURCE")!)
                switch joinColumns.count {
                case 1:
                    joinParam1 = Array(joinColumns)[0]
                    allInDataTable = allInDataTable.join(with: currentMLDataTable, on: joinParam1)
                case 2:
                    joinParam1 = Array(joinColumns)[0]
                    joinParam2 = Array(joinColumns)[1]
                    allInDataTable = allInDataTable.join(with: currentMLDataTable, on: joinParam1, joinParam2, type: .inner)
                default: print("no join colums")
                }
            }
            allInDataTable.removeColumn(named: "COGNITIONSOURCE")
        }
        for cognitionObject in cognitionObjects {
            guard let currentMLDataTable = cognitionObject.coreDataML?.mlDataTable else {
                fatalError("no mldatatable found in coginition source.")
            }
            let joinColums = Set(allInDataTable.columnNames).intersection(currentMLDataTable.columnNames)
            switch joinColums.count {
            case 1:
                joinParam1 = Array(joinColums)[0]
                allInDataTable = allInDataTable.join(with: currentMLDataTable, on: joinParam1)
            case 2:
                joinParam1 = Array(joinColums)[0]
                joinParam2 = Array(joinColums)[1]
                allInDataTable = allInDataTable.join(with: currentMLDataTable, on: joinParam1, joinParam2, type: .inner)
            default: print("no join colums")
            }
        }
        allInDataTable.removeColumn(named: "COGNITIONOBJECT")
        self.orderedColumns = orderColumns(allColumns: allColumns)
        return allInDataTable
    }
    static func getColumnPivotValue(pivotColum: Columns?) ->String? {
        return FileWeaver.valuesDataModel.items.filter { $0.value2column == pivotColum}.first?.value
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

