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
    var numCols: Int = 0
    var numRows : Int = 0
    
    var gridItems: [GridItem]!
    @ObservedObject var valuesTableProvider: ValuesTableProvider
    var customColumns: [CustomColumn]!
    
    struct CellIndex: Identifiable {
        let id: Int
        let colIndex: Int
        let rowIndex: Int
    }
    init(valuesTableProvider: ValuesTableProvider) {
        self.valuesTableProvider = valuesTableProvider
        self.customColumns = valuesTableProvider.customColumns
        self.gridItems = valuesTableProvider.gridItems
        numCols = valuesTableProvider.numCols
        numRows = valuesTableProvider.numRows
    }
    
    var body: some View {
        let cells = (0..<numRows).flatMap{j in customColumns.enumerated().map{(i,c) in CellIndex(id:j + i*numRows, colIndex:i, rowIndex:j)}}
        ScrollView([.vertical], showsIndicators: true) {
            LazyVGrid(columns:gridItems, pinnedViews: [.sectionHeaders], content: {
                Section(header: stickyHeaderView) {
                    ForEach(cells) { cellIndex in
                        let column = customColumns[cellIndex.colIndex]
                        Text(column.betterRows[cellIndex.rowIndex]).padding(.horizontal)
                            .font(.body).monospacedDigit()
                            .scaledToFit()
                        
                    }
                }
            })
        }
        .background(.white)
        .padding(.horizontal)
        
    }
    var stickyHeaderView: some View {
        VStack(spacing: 10) {
            Rectangle()
                .fill(Color.gray)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 40, maxHeight: .infinity)
                .overlay(
                    LazyVGrid(columns: gridItems) {
                        ForEach(customColumns) { col in
                            Text(col.title)
                                .foregroundColor(Color.white)
                                .font(.body)
                                .scaledToFit()
                                .padding(.horizontal)
                        }
                    }
                )
            Rectangle()
                .fill(Color.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 40, maxHeight: .infinity)
                .overlay(
                     stickyFilterView(columns: customColumns)
                )
        }.padding(0)
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
        return ValuesView(valuesTableProvider: ValuesTableProvider(file: FilesModel().items.first!))
    }
}
