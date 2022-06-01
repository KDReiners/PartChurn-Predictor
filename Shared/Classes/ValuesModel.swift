//
//  ValuesModel.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 06.05.22.
//

import Foundation
import CoreData
import CoreML
import CreateML
import SwiftUI
public class ValuesModel: Model<Values> {
    @Published var result: [Values]!
    public init() {
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
    }
    override public var items: [Values] {
        get {
            return result
        }
        set
        {
            result = newValue
        }
    }
    public func recordCount(model: Models) -> Int {
        let lastValue = (model.model2values?.allObjects as? [Values])!.max(by: {(value1, value2)-> Bool in
            return value1.rowno < value2.rowno
        } )
        guard let lastValue = lastValue else {
            return 0
        }
        return Int(lastValue.rowno)
    }
    public struct mlTableView: View {
        var coreDataML: CoreDataML
        var mlTable: MLDataTable
        var orderedColumns: [Columns]
        var mlDataRows = [MLDataRow]()
        init(coreDataML: CoreDataML) {
            self.mlTable = coreDataML.baseData
            self.orderedColumns = coreDataML.orderedColumns
            self.coreDataML = coreDataML
            mlDataRows = resolve()
        }
        public var body: some View {
            VStack {
                ForEach(0..<mlDataRows.count, id: \.self) { rowIndex in
                    HStack {
                        ForEach(0..<mlDataRows[rowIndex].columns.count, id: \.self) { colIndex in
                            Text(mlDataRows[rowIndex].columns[colIndex])
                        }
                    }
                }
            }
        }
        func resolve() -> [MLDataRow] {
            var result = [MLDataRow]()
            print("Löse auf")
            for (index, row) in mlTable.rows.enumerated() {
                var rowWithColumns = MLDataRow(rowIndex: index)
                for column in orderedColumns {
                    if let intValue = row[column.name!]?.intValue {
                        rowWithColumns.columns.append("\(intValue)")
                    }
                    if let doubleValue = row[column.name!]?.doubleValue {
                        rowWithColumns.columns.append("\(doubleValue)")
                    }
                    if let  stringValue = row[column.name!]?.stringValue {
                        rowWithColumns.columns.append(stringValue)
                    }
                }
                result.append(rowWithColumns)
            }
            return result
        }
        struct MLDataRow {
            var rowIndex: Int
            var columns = [String]()
        }
    }
}

