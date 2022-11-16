//
//  ValuesView.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 08.06.22.
//

import Foundation
import SwiftUI
import CoreML
import CreateML
import CSV
import Combine
struct ValuesView: View {
    
    @ObservedObject var mlDataTableFactory: MlDataTableProvider
    var masterDict = Dictionary<String, String>()
    @State var size: CGSize = .zero
    @State var headerSize: CGSize = .zero
    
    struct CellIndex: Identifiable {
        let id: Int
        let colIndex: Int
        let rowIndex: Int
    }
    
    init(mlDataTableProvider: MlDataTableProvider) {
        self.mlDataTableFactory = mlDataTableProvider
    }
    init(file: Files) {
        self.mlDataTableFactory = MlDataTableProvider()
        self.mlDataTableFactory.orderedColumns = file.file2columns?.allObjects as? [Columns]
        self.mlDataTableFactory.selectedColumns = self.mlDataTableFactory.orderedColumns
        self.mlDataTableFactory.mergedColumns = self.mlDataTableFactory.orderedColumns
        self.mlDataTableFactory.updateTableProvider(file: file)
        
    }
    var body: some View {
        if mlDataTableFactory.loaded == false {
            Text("load table...")
        } else {
            let cells = (0..<mlDataTableFactory.numRows).flatMap{j in mlDataTableFactory.customColumns.enumerated().map{(i,c) in CellIndex(id:j + i*mlDataTableFactory.numRows, colIndex:i, rowIndex:j)}}
            ScrollView(.horizontal, showsIndicators: true) {
                ScrollView([.vertical], showsIndicators: true) {
                    LazyVGrid(columns:mlDataTableFactory.gridItems, pinnedViews: [.sectionHeaders], content: {
                        Section(header: stickyHeaderView .background(
                            GeometryReader { geometryProxy in
                                Color.white
                                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
                            }))
                        {
                            ForEach(cells) { cellIndex in
                                let column = mlDataTableFactory.customColumns[cellIndex.colIndex]
                                Text(column.rows[cellIndex.rowIndex])
                                    .onTapGesture {
                                        print(cellIndex.rowIndex)
                                        self.mlDataTableFactory.mlDataTable.removeColumn(named: "Predicted: N_ALIVE")
                                        self.mlDataTableFactory.mlRowDictionary = (self.mlDataTableFactory.valuesTableProvider?.convertRowToDicionary(mlRow: self.mlDataTableFactory.mlDataTable.rows[cellIndex.rowIndex]))!
                                        self.mlDataTableFactory.selectedRowIndex = cellIndex.rowIndex
                                    }
                                    .padding(.horizontal)
                                    .font(.body).monospacedDigit()
                                    .scaledToFit()
                            }
                        }
                    })
                }
                .background(.white)
                .frame(width: headerSize.width)
            }
            .background(
                GeometryReader { geometryProxy in
                    Color.white
                        .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
                })
            .onPreferenceChange(SizePreferenceKey.self) { newSize in
                print("The new child size is: \(newSize)")
                size = newSize
                let tableWidth = CGFloat(mlDataTableFactory.sizeOfHeaders()) * 12 + CGFloat(mlDataTableFactory.mlColumns!.count) * 15
                headerSize.width = newSize.width > tableWidth ? newSize.width: tableWidth
            }
        }
        Button("Save") {
            //                var localUrl = URL(fileURLWithPath:BaseServices.homePath.appendingPathComponent("ChurnOutput.csv", isDirectory: false).path)
            let savePanel = NSSavePanel()
            savePanel.canCreateDirectories = true
            let response = savePanel.runModal()
            guard response == .OK, let localUrl = savePanel.url else { return }
            writeCSV(url: localUrl, exportTable: mlDataTableFactory.mlDataTable)
            
            
        }
    }
    var stickyHeaderView: some View {
        VStack(spacing: 10) {
            LazyVGrid(columns: mlDataTableFactory.gridItems) {
                ForEach(mlDataTableFactory.customColumns) { col in
                    Text(col.title)
                        .foregroundColor(Color.blue)
                        .font(.body)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: true, vertical: true)
                }
            }
            
            Rectangle()
                .fill(Color.white)
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .overlay(
                    mlDataTableFactory.filterViewProvider.tableFilterView
                )
        }
        .background(.white)
        .padding(.bottom)
    }
    private func writeCSV(url: URL, exportTable: MLDataTable) {
        var stream: OutputStream
        if #available(macOS 13.0, *) {
            stream = OutputStream(toFileAtPath: url.path(), append: false)!
        } else {
            stream = OutputStream(toFileAtPath: url.path, append: false)!
        }
        let csv = try! CSVWriter(stream: stream, delimiter: ";")
        csv.beginNewRow()
        for col in mlDataTableFactory.valuesTableProvider!.orderedColNames {
            try? csv.write(field: col)
        }
        for i in 0..<(exportTable.rows.count) {
            let row = exportTable.rows[i]
            csv.beginNewRow()
            for col in mlDataTableFactory.valuesTableProvider!.orderedColNames {
                if exportTable.columnNames.contains(col) == true {
                    let valueType = row[col]!.type
                    switch valueType {
                    case MLDataValue.ValueType.int:
                        try? csv.write(field: String(row[col]!.intValue!))
                    case MLDataValue.ValueType.double:
                        try? csv.write(field: String(row[col]!.doubleValue!).replacingOccurrences(of: ".", with: ","))
                    case MLDataValue.ValueType.string:
                        try? csv.write(field: row[col]!.stringValue!)
                    default:
                        print("error determining value type")
                    }
                }else {
                    print("cannot find: \(col)")
                }
            }
            
        }
        csv.stream.close()
    }
}
struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}
