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

internal class Composer {
    var model: Models
    var files: NSSet!
    var mlDataTable_Base: MLDataTable!
    var columnsDataModel = ColumnsModel()
    var orderedColumns: [Columns]
    var timeBasedColumns: [String]
    var primaryKeyColumns: [String]
    
    static var valuesDataModel = ValuesModel()
    var cognitionSources = [CognitionSource]()
    var cognitionObjects = [CognitionObject]()
    init(model: Models)
    {
        self.orderedColumns = Array(model.model2columns?.allObjects as! [Columns]).sorted(by: { $0.orderno < $1.orderno})
        self.model = model
        self.files = model.model2files
        self.timeBasedColumns = Array(model.model2columns?.allObjects as! [Columns]).filter({ $0.ispartoftimeseries == 1 }).map( {
            $0.name!
        })
        self.primaryKeyColumns = Array(model.model2columns?.allObjects as! [Columns]).filter({ $0.ispartofprimarykey == 1 }).map( {
            $0.name!
        })
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
        var joinParam1: String = ""
        var joinParam2: String = ""
        var test: MLDataTable?
        var allInDataTable = MLDataTable()
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
                    allInDataTable = allInDataTable.join(with: currentMLDataTable, on: joinParam1, joinParam2)
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
                allInDataTable = allInDataTable.join(with: currentMLDataTable, on: joinParam1, joinParam2)
            default: print("no join colums")
            }
        }
        allInDataTable.removeColumn(named: "COGNITIONOBJECT")
        
        test = allInDataTable.intersect(201712, of: "I_REPORTMONTH")
        print(test)
        return allInDataTable
    }
    private func reduceColumns(allInDataTable: MLDataTable ) {
        var result: MLDataTable
        result = allInDataTable[primaryKeyColumns]
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

