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
        init(coreDataML: CoreDataML) {
            self.mlTable = coreDataML.baseData
            self.orderedColumns = coreDataML.orderedColumns
            self.coreDataML = coreDataML
        }
        public var body: some View {
            VStack {
                ForEach(0..<mlTable.rows.count, id: \.self) { rowIndex in
                    HStack {
                        ForEach(0..<orderedColumns.count, id: \.self) { nameIndex in
                            Text(resolve(rowIndex:rowIndex, nameIndex:nameIndex)).padding()
                        }
                    }
                }
            }
        }
        func resolve(rowIndex: Int, nameIndex: Int) ->String {
            guard let columnName = self.orderedColumns[nameIndex].name else {
                fatalError()
            }
            if let intValue = mlTable.rows[rowIndex][columnName]?.intValue {
                return "\(intValue)"
            }
            if let doubleValue = mlTable.rows[rowIndex][columnName]?.doubleValue {
                return "\(doubleValue)"
            }
            if let  stringValue = mlTable.rows[rowIndex][columnName]?.stringValue {
                return stringValue
            }
            return "Error"
        }
    }
}

