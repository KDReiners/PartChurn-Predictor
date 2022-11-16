//
//  PredictionView.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 13.11.22.
//

import SwiftUI

struct PredictionView: View {
    @ObservedObject var mlDataTableProvider: MlDataTableProvider
    var mlDataTableProviderContext: SimulationController.MlDataTableProviderContext
    //    @State var valuesView: ValuesView?
    struct CellIndex: Identifiable {
        let id: Int
        let colIndex: Int
        let rowIndex: Int
    }
    init(mlDataTableProviderContext: SimulationController.MlDataTableProviderContext ) {
        self.mlDataTableProviderContext = mlDataTableProviderContext
        self.mlDataTableProvider = self.mlDataTableProviderContext.mlDataTableProvider
    }
    
    var body: some View {
        if self.mlDataTableProvider.loaded == false {
            Text("load table...")
        } else {
            VStack(alignment: .leading) {
                Text("Hello dear prediction")
                let cells = (0..<1).flatMap{j in self.mlDataTableProviderContext.mlDataTableProvider.customColumns.enumerated().map{(i,c) in CellIndex(id:j + i*1, colIndex:i, rowIndex:j)}}
                let gridItems = [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .trailing), GridItem(.flexible()),  GridItem(.flexible(), alignment: .trailing)]
                ScrollView([.vertical], showsIndicators: true) {
                    LazyVGrid(columns: gridItems) {
                        ForEach(cells) { cellIndex in
                            let column = self.mlDataTableProviderContext.mlDataTableProvider.customColumns[cellIndex.colIndex]
                            Text(column.title)
                                .font(.body.bold())
                            Text(column.rows[self.mlDataTableProviderContext.mlDataTableProvider.selectedRowIndex ?? 0])
                            self.mlDataTableProviderContext.getView(customColumn: column, rowIndex: self.mlDataTableProvider.selectedRowIndex ?? 0)
                                .font(.callout)
                            Button("Apply") {
                                self.mlDataTableProvider.valuesTableProvider?.predict(regressorName: "BoostedTreeRegressor", result: self.mlDataTableProvider.mlRowDictionary)
                            }
                        }
                    }
                    .padding()
                }
                .background(.white)
            }
        }
    }
}
