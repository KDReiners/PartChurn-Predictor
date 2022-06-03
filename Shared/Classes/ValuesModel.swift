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
    struct Column: Identifiable {
        let id = UUID()
        var title: String
        var enabled: Bool = true
        var rows: [String] = []
    }
    
    struct mlTableView: View {
        var coreDataML: CoreDataML
        var mlTable: MLDataTable
        
        var columns = [Column]()
        var maxRows: Int = 0
        
        struct CellIndex: Identifiable {
            let id: Int
            let colIndex: Int
            let rowIndex: Int
        }
        init( coreDataML: CoreDataML?) {
            self.coreDataML = coreDataML!
            mlTable = self.coreDataML.baseData
            resolve()
        }
        mutating func resolve() -> Void {
            for column in self.coreDataML.orderedColumns {
                var newColumn = Column(title: column.name ?? "Unbekannt")
                for row in mlTable.rows {
                    if let intValue = row[column.name!]?.intValue {
                        newColumn.rows.append("\(intValue)")
                    }
                    if let doubleValue = row[column.name!]?.doubleValue {
                        newColumn.rows.append("\(doubleValue)")
                    }
                    if let  stringValue = row[column.name!]?.stringValue {
                        newColumn.rows.append(stringValue)
                    }
                }
                self.columns.append(newColumn)
            }
            
        }
        var body: some View {
            let numCols = columns.count
            let numRows = columns[0].rows.count
            let columnItems: [GridItem] = Array(repeating: .init(.flexible()), count: numCols)
            let cells = (0..<numRows).flatMap{j in columns.enumerated().map{(i,c) in CellIndex(id:j + i*numRows, colIndex:i, rowIndex:j)}}
            return ScrollView {
                LazyHGrid(rows: columnItems) {
                    Text("Header")
                }
                    LazyVGrid(columns:columnItems) {
                        ForEach(cells) { cellIndex in
                            let column = columns[cellIndex.colIndex]
                            HStack {
                                //                            Text("\(cellIndex.colIndex)")
                                Text("\(column.rows[cellIndex.rowIndex])")
                                Spacer()
                            }
                        }
                    }
                    .padding(.bottom)
                    //                .padding(.bottom, 44*4)
                
            }
        }
    }
    
    struct DataGridView_Previews: PreviewProvider {
        static var previews: some View {
            return mlTableView(coreDataML: nil)
        }
    }
}

