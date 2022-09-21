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
    
    @ObservedObject var mlDataTableFactory: MlDataTableProvider
    var masterDict = Dictionary<String, String>()
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
        }
        Button("Save") {
            do {
                try self.mlDataTableFactory.mlDataTable!.writeCSV(to: URL(fileURLWithPath:BaseServices.homePath.appendingPathComponent("Khaled.csv", isDirectory: false).path))
            } catch {
                print("Error saving table")
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
                    mlDataTableFactory.filterViewProvider.tableFilterView
                )
        }
        .background(.white)
        .padding(.bottom)
    }
}
