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
        
    }
    struct CellIndex: Identifiable {
        let id: Int
        let colIndex: Int
        let rowIndex: Int
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
                    loader.gridItems = result.gridItems
                    loader.customColumns = result.customColumns
                    loader.loaded = true
                    loader.numRows = loader.customColumns.count > 0 ? loader.customColumns[0].betterRows.count:0
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
                 }
                 var stickyHeaderView: some View {
                VStack(spacing: 10) {
                    Rectangle()
                        .fill(Color.gray)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 40, maxHeight: .infinity)
                        .overlay(
                            LazyVGrid(columns: loader.gridItems) {
                                ForEach(loader.customColumns) { col in
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
                            stickyFilterView(columns: loader.customColumns)
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
                    return ValuesView(file: FilesModel().items.first!)
                }
            }
