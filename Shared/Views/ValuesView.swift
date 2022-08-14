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
    var unionResult: UnionResult!
    var masterDict = Dictionary<String, String>()
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
        unionResult = mlDataTableFactory.buildMlDataTable()
        self.mlDataTable = unionResult.mlDataTable
    }
    init(file: Files) {
        loadValuesTableProvider(file: file)
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
//                    TableFilterView(columns: mlDataTableFactory.customColumns, gridItems: mlDataTableFactory.gridItems, mlDataTableFactory: self.mlDataTableFactory)
                    mlDataTableFactory.filterViewProvider.tableFilterView
                )
        }
        .background(.white)
        .padding(.bottom)
    }
}

struct ValuesView_Previews: PreviewProvider {
    static var previews: some View {
        return ValuesView(file: FilesModel().items.first!)
    }
}
