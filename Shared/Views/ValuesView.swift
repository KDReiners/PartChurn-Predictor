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
struct ValuesView: View {
    
    @ObservedObject var mlDataTableFactory = MlDataTableFactory()
    var mlDataTable: MLDataTable?
    struct CellIndex: Identifiable {
        let id: Int
        let colIndex: Int
        let rowIndex: Int
    }
    
    
    
    init(mlDataTable: MLDataTable, orderedColumns: [Columns], selectedColumns: [Columns]? = nil, timeSeriesRows: [String]? = nil) {
        mlDataTableFactory.orderedColumns = orderedColumns
        mlDataTableFactory.mlDataTable = mlDataTable
        mlDataTableFactory.selectedColumns = selectedColumns
        if let timeSeriesRows = timeSeriesRows {
            var selectedTimeSeries = [[Int]]()
            for row in timeSeriesRows {
                let innerResult = row.components(separatedBy: ", ").map { Int($0)! }
                selectedTimeSeries.append(innerResult)
            }
            mlDataTableFactory.timeSeries = selectedTimeSeries
        }
        
        let unionResult = mlDataTableFactory.filterMlDataTable()
        self.mlDataTable = unionResult.mlDataTable
        loadValuesTableProvider(mlDataTable: unionResult.mlDataTable, orderedColums: unionResult.orderedColumns)
    }
    init(file: Files) {
        loadValuesTableProvider(file: file)
    }
    
    func loadValuesTableProvider(mlDataTable: MLDataTable, orderedColums: [String]) -> Void {
        var result: ValuesTableProvider!
        do {
            let sampler = DispatchQueue(label: "KD", qos: .userInitiated, attributes: .concurrent)
            sampler.async {
                result =  ValuesTableProvider(mlDataTable: mlDataTable, orderedColumns: orderedColums)
                DispatchQueue.main.async {
                    mlDataTableFactory.gridItems = result.gridItems
                    mlDataTableFactory.customColumns = result.customColumns
                    mlDataTableFactory.loaded = true
                    mlDataTableFactory.numRows = mlDataTableFactory.customColumns.count > 0 ? mlDataTableFactory.customColumns[0].rows.count:0
                }
            }
        }
    }
    func loadValuesTableProvider(file: Files) -> Void {
        var result: ValuesTableProvider!
        do {
            let sampler = DispatchQueue(label: "KD", qos: .userInitiated, attributes: .concurrent)
            sampler.async {
                result =  ValuesTableProvider(file: file)
                DispatchQueue.main.async {
                    mlDataTableFactory.gridItems = result.gridItems
                    mlDataTableFactory.customColumns = result.customColumns
                    mlDataTableFactory.loaded = true
                    mlDataTableFactory.numRows = mlDataTableFactory.customColumns.count > 0 ? mlDataTableFactory.customColumns[0].rows.count:0
                }
            }
        }
    }
    var body: some View {
        if mlDataTableFactory.loaded == false {
            Text("load table...")
        } else {
            let cells = (0..<mlDataTableFactory.numRows).flatMap{j in mlDataTableFactory.customColumns.enumerated().map{(i,c) in CellIndex(id:j + i*mlDataTableFactory.numRows, colIndex:i, rowIndex:j)}}
            ScrollView([.vertical], showsIndicators: true) {
                LazyVGrid(columns:mlDataTableFactory.gridItems, pinnedViews: [.sectionHeaders], content: {
                    Section(header: stickyHeaderView) {
                        ForEach(cells) { cellIndex in
                            let column = mlDataTableFactory.customColumns[cellIndex.colIndex]
                            Text(column.rows[cellIndex.rowIndex])
                                .padding(.horizontal)
                                .font(.body).monospacedDigit()
                                .scaledToFit()
                            
                        }
                    }
                })
            }
            .background(.white)
            .padding(.horizontal)
        }
        Button("Save") {
            do {
                try self.mlDataTable!.writeCSV(to: URL(fileURLWithPath:"/Users/klaus.reiners/Library/Containers/peas.com.PartChurn-Predictor/Data/Library/Application Support/PartChurn Predictor/Khaled.csv"))
            } catch {
                print("")
            }
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
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Rectangle()
                .fill(Color.white)
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .overlay(
                    stickyFilterView(columns: mlDataTableFactory.customColumns, gridItems: mlDataTableFactory.gridItems)
                )
        }
        .background(.white)
        .padding(.bottom)
    }
    struct stickyFilterView: View {
        var gridItems: [GridItem]
        var columns: [CustomColumn]
        @State var filterDict = Dictionary<String, String>()
        init(columns: [CustomColumn], gridItems: [GridItem]) {
            self.columns = columns
            self.gridItems = gridItems
            for column in columns {
                filterDict[column.title] = ""
            }
        }
        var body: some View {
            LazyVGrid(columns: gridItems) {
                ForEach(columns) { col in
                    TextField(col.title, text: binding(for: col.title)).frame(alignment: .trailing)
                        .onSubmit {
                            print(binding(for: col.title))
                        }
                }
            }
        }
        private func binding(for key: String) -> Binding<String> {
            return Binding(get: {0
                return self.filterDict[key] ?? ""
            }, set: {
                self.filterDict[key] = $0
            })
        }
        
    }
}

struct ValuesView_Previews: PreviewProvider {
    static var previews: some View {
        return ValuesView(file: FilesModel().items.first!)
    }
}
