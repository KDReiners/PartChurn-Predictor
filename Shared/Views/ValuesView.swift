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
    
    @ObservedObject var loader = Loader()
    
    class Loader: ObservableObject {
        @Published var loaded = false
        var gridItems: [GridItem]!
        var numRows: Int = 0
        var customColumns = [CustomColumn]()
        var mlDataTable: MLDataTable!
        var unionOfMlDataTables: [MLDataTable]?
        var orderedColumns: [Columns]!
        var selectedColumns: [Columns]?
        var mergedColumns: [Columns]!
        var timeSeries: [Int]?
        
        func filterMlDataTable() {
            var result: MLDataTable!
            mergedColumns = selectedColumns == nil ? orderedColumns: selectedColumns
            if selectedColumns != nil {
                let additions = orderedColumns.filter { $0.ispartofprimarykey == 1 || $0.istimeseries == 1 || $0.istarget == 1}
                mergedColumns.append(contentsOf: additions)
            }
            let timeSeriesColumn = self.orderedColumns.filter { $0.istimeseries == 1 }
            let mlTimeSeriesColumn = mlDataTable[(timeSeriesColumn.first?.name!)!]
            if let timeSeries = timeSeries {
                for timeSlice in timeSeries {
                    let timeSeriesMask = mlTimeSeriesColumn == timeSlice
                    let newMlDataTable = self.mlDataTable[timeSeriesMask]
                    if unionOfMlDataTables == nil {
                        unionOfMlDataTables = [newMlDataTable] } else {
                            unionOfMlDataTables?.append(newMlDataTable)
                        }
                }
                if var unionTables = unionOfMlDataTables {
                    adjustTables(unionOfMlDataTables: &unionTables)
                    let joinColumn = orderedColumns.first(where: { $0.ispartofprimarykey == 1 })
                    for mlDataTableForUnion in unionTables {
                        if result == nil {
                            result = mlDataTableForUnion
                        } else {
                            result = result.join(with: mlDataTableForUnion, on: (joinColumn?.name!)!, type: .inner)
                        }
                    }
                }
                self.mlDataTable = result
            }
        }
        func adjustTables(unionOfMlDataTables: inout [MLDataTable]) {
            let seriesDataModel = SeriesModel()
            seriesDataModel.deleteAllRecords(predicate: nil)
            /// extract non timeSeriesColumn from self.mlDataTable
            let timeSeriesColumns = self.orderedColumns.filter { $0.istimeseries == 1 }
            for column in timeSeriesColumns  {
                mlDataTable.removeColumn(named: column.name!)
            }
            /// rename timeSeriesColumns from each mlDataTable in unionOfMlDataTables
            let timeDependantColumns = self.orderedColumns.filter { $0.istimeseries == 0 && $0.ispartofprimarykey == 0}
            for i in 0..<unionOfMlDataTables.count {
                for column in timeDependantColumns {
                    if unionOfMlDataTables[i].columnNames.contains(column.name!) {
                        unionOfMlDataTables[i].renameColumn(named: column.name!, to: column.name! + " T-(\(i))")
                        let newSeries = SeriesModel().insertRecord()
                        newSeries.timeslice = Int16(i)
                        newSeries.alias = column.name! + " T-(\(i))"
                        newSeries.series2column = column    
                        column.alias = column.name! + " T-(\(i))"
                    }
                }
            }
        }
    }
    struct CellIndex: Identifiable {
        let id: Int
        let colIndex: Int
        let rowIndex: Int
    }

 
    
    init(mlDataTable: MLDataTable, orderedColumns: [Columns], selectedColumns: [Columns]? = nil, selectedTimeSeries: [Int]? = nil) {
        loader.orderedColumns = orderedColumns
        loader.mlDataTable = mlDataTable
        loader.selectedColumns = selectedColumns
        loader.timeSeries = selectedTimeSeries
        loader.filterMlDataTable()
        loadValuesTableProvider(mlDataTable: loader.mlDataTable, orderedColums: loader.mergedColumns.sorted(by: { $0.orderno < $1.orderno }))
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
                    loader.gridItems = result.gridItems
                    loader.customColumns = result.customColumns
                    loader.loaded = true
                    loader.numRows = loader.customColumns.count > 0 ? loader.customColumns[0].rows.count:0
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
                    loader.gridItems = result.gridItems
                    loader.customColumns = result.customColumns
                    loader.loaded = true
                    loader.numRows = loader.customColumns.count > 0 ? loader.customColumns[0].rows.count:0
                }
            }
        }
    }
    var body: some View {
        if loader.loaded == false {
            Text("load table...")
                 } else {
                let cells = (0..<loader.numRows).flatMap{j in loader.customColumns.enumerated().map{(i,c) in CellIndex(id:j + i*loader.numRows, colIndex:i, rowIndex:j)}}
                     ScrollView([.vertical], showsIndicators: true) {
                    LazyVGrid(columns:loader.gridItems, pinnedViews: [.sectionHeaders], content: {
                        Section(header: stickyHeaderView) {
                            ForEach(cells) { cellIndex in
                                let column = loader.customColumns[cellIndex.colIndex]
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
                            LazyVGrid(columns: loader.gridItems) {
                                ForEach(loader.customColumns) { col in
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
                            stickyFilterView(columns: loader.customColumns)
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
