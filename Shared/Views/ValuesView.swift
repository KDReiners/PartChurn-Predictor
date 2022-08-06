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
    
    struct CellIndex: Identifiable {
        let id: Int
        let colIndex: Int
        let rowIndex: Int
    }

 
    
    init(mlDataTable: MLDataTable, orderedColumns: [Columns], selectedColumns: [Columns]? = nil, selectedTimeSeries: [Int]? = nil) {
        mlDataTableFactory.orderedColumns = orderedColumns
        mlDataTableFactory.mlDataTable = mlDataTable
        mlDataTableFactory.selectedColumns = selectedColumns
        mlDataTableFactory.timeSeries = selectedTimeSeries
        mlDataTableFactory.filterMlDataTable()
        loadValuesTableProvider(mlDataTable: mlDataTableFactory.mlDataTable, orderedColums: mlDataTableFactory.mergedColumns.sorted(by: { $0.orderno < $1.orderno }))
    }
    init(file: Files) {
        loadValuesTableProvider(file: file)
    }
   
    func loadValuesTableProvider(mlDataTable: MLDataTable, orderedColums: [Columns]) -> Void {
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
                 }
                 var stickyHeaderView: some View {
                VStack(spacing: 10) {
                    Rectangle()
                        .fill(Color.gray)
                        .frame(maxWidth: .infinity, minHeight: 40, maxHeight: .infinity)
                        .overlay(
                            LazyVGrid(columns: mlDataTableFactory.gridItems) {
                                ForEach(mlDataTableFactory.customColumns) { col in
                                    Text(col.title)
                                        .foregroundColor(Color.white)
                                        .font(.body)
                                        .scaledToFit()
                                        .padding(.horizontal)
                                        .multilineTextAlignment(.center)
                                }
                            }
                        )
                    Rectangle()
                        .fill(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: .infinity)
                        .overlay(
                            stickyFilterView(columns: mlDataTableFactory.customColumns)
                        )
                }
                .background(.white)
                .padding(.bottom)
            }
                struct stickyFilterView: View {
                var columns: [CustomColumn]
                @State var filterDict = Dictionary<String, String>()
                init(columns: [CustomColumn]) {
                    self.columns = columns
                    for column in columns {
                        filterDict[column.title] = ""
                    }
                }
                var body: some View {
                    ForEach(columns) { col in
                        TextField(col.title, text: binding(for: col.title))
                            .onSubmit {
                                print(binding(for: col.title))
                            }
                    }
                }
                private func binding(for key: String) -> Binding<String> {
                    return Binding(get: {
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
