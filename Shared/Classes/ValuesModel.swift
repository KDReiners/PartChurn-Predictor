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
        var alignment: Alignment
    }
    struct ContentView: View {
        let gridItems = [
            GridItem(spacing: 50, alignment: .leading),
            GridItem(),
            GridItem(alignment: .trailing)
        ]
        
        var body: some View {
            var rows: [GridItem] =
                    Array(repeating: .init(.fixed(20)), count: 3)
            ScrollView(.horizontal) {
                LazyHGrid(rows: rows, alignment: .top) {
                    ForEach((0...79), id: \.self) {
                        let codepoint = $0 + 0x1f600
                        let codepointString = String(format: "%02X", codepoint)
                        Text("\(codepointString)")
                            .font(.footnote)
                        let emoji = String(Character(UnicodeScalar(codepoint)!))
                        Text("\(emoji)")
                            .font(.largeTitle)
                    }
                }
            }
        }
    }
    
    struct mlTableView: View {
        var numCols: Int = 0
        var numRows : Int = 0
        var columnItems = [GridItem]()
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
            numCols = columns.count
            numRows = columns[0].rows.count
            //            columnItems = Array(repeating: .init(.flexible()), count: numCols)
            
        }
        mutating func resolve() -> Void {
            var valueFormatter: NumberFormatter = {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.maximumFractionDigits = 2
                return formatter
            }()
            for column in self.coreDataML.orderedColumns {
                var newColumn = Column(title: column.name ?? "Unbekannt", alignment: .trailing)
                var newGridItem: GridItem?
                for row in mlTable.rows {
                    if let intValue = row[column.name!]?.intValue {
                        newColumn.rows.append(valueFormatter.string(from: intValue as NSNumber)!)
//                        newColumn.rows.append("\(intValue)")
                        newColumn.alignment = .trailing
                        newGridItem = GridItem(.flexible(), spacing: 10, alignment: .trailing)
                    }
                    if let doubleValue = row[column.name!]?.doubleValue {
                        newColumn.rows.append("\(doubleValue)")
                        newColumn.alignment = .trailing
                        newGridItem = GridItem(.flexible(),spacing: 10, alignment: .trailing)
                    }
                    if let  stringValue = row[column.name!]?.stringValue {
                        newColumn.rows.append(stringValue)
                        newColumn.alignment = .leading
                        newGridItem = GridItem(.flexible(),spacing: 10, alignment: .leading)
                    }
                }
                self.columns.append(newColumn)
                self.columnItems.append(newGridItem!)
            }
            
        }
        var body: some View {
            
            let cells = (0..<numRows).flatMap{j in columns.enumerated().map{(i,c) in CellIndex(id:j + i*numRows, colIndex:i, rowIndex:j)}}
            ScrollView([.vertical], showsIndicators: true) {
                LazyVGrid(columns:columnItems, pinnedViews: [.sectionHeaders], content: {
                    Section(header: stickyHeaderView) {
                        ForEach(cells) { cellIndex in
                            let column = columns[cellIndex.colIndex]
                            Text(column.rows[cellIndex.rowIndex])
                                .font(.body).monospacedDigit()
                                .scaledToFit()

                        }
                    }
                })
            }.background(.white)
            
        }
        var stickyHeaderView: some View {
            Rectangle()
                .fill(Color.gray)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 40, maxHeight: .infinity)
                .overlay(
                    LazyVGrid(columns: columnItems) {
                        ForEach(columns) { col in
                            Text(col.title)
                                .foregroundColor(Color.white)
                                .font(.body)
                        }
                    }
                )
        }
    }
    
    struct DataGridView_Previews: PreviewProvider {
        static var previews: some View {
            return mlTableView(coreDataML: nil)
        }
    }
}

