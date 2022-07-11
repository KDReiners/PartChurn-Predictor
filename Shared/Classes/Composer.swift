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
    var columnsDataModel = ColumnsModel()
    static var valuesDataModel = ValuesModel()
    var cognitionSources = [CognitionSource]()
    var cognitionObjects = [CognitionObject]()
    init(model: Models)
    {
        self.model = model
        self.files = model.model2files
        examine()
    }
    private func examine() -> Void {
        for file in files {
            let columns = columnsDataModel.items.filter { $0.column2file == file as? Files}
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
    static func getColumnPivotValue(pivotColum: Columns?) ->String? {
        return Composer.valuesDataModel.items.filter { $0.value2column == pivotColum}.first?.value
    }
    internal struct CognitionSource: Identifiable {
        var id = UUID()
        var name: String!
        var columns: [Columns]
        var valueColumns: [Columns]
        init(columns: [Columns]) {
            self.columns = columns
            let coginitionSourceColumn = columns.filter { return $0.name == "COGNITIONSOURCE"}.first
            self.name = getColumnPivotValue(pivotColum: coginitionSourceColumn)
            self.valueColumns = columns.filter { return $0.name != "COGNITIONSOURCE" }
        }
    }
    internal struct CognitionObject: Identifiable {
        var id = UUID()
        var name: String!
        var columns: [Columns]
        var valueColumns: [Columns]
        init(columns: [Columns]) {
            self.columns = columns
            let cognitionObjectColumn = columns.filter { return $0.name == "COGNITIONOBJECT"}.first
            self.name = getColumnPivotValue(pivotColum: cognitionObjectColumn)
            self.valueColumns = columns.filter { return $0.name != "COGNITIONOBJECT" }
            
        }
    }
}

