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
    @State var newPredictedValue: Double?
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
                if self.mlDataTableProvider.mlRowDictionary.count > 0 {
                    let targetColumn = self.mlDataTableProviderContext.mlDataTableProvider.customColumns.first(where: { $0.title == self.mlDataTableProvider.valuesTableProvider?.predictedColumnName })
                    let rowIndex = self.mlDataTableProviderContext.mlDataTableProvider.selectedRowIndex
                    let predictedValue = targetColumn?.rows[rowIndex!]
                    HStack() {
                        Text("Table Prediction Value: ")
                        Text(String(predictedValue!))
                        Text("New PredictedValue: ")
                        Text(String($newPredictedValue.wrappedValue ?? -99))
                    }
                }
                let cells = (0..<1).flatMap{j in self.mlDataTableProviderContext.mlDataTableProvider.customColumns.enumerated().map{(i,c) in CellIndex(id:j + i*1, colIndex:i, rowIndex:j)}}
                let gridItems = [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .trailing), GridItem(.flexible()),  GridItem(.flexible(), alignment: .trailing)]
                ScrollView([.vertical], showsIndicators: true) {
                    LazyVGrid(columns: gridItems) {
                        ForEach(cells) { cellIndex in
                            let column = self.mlDataTableProviderContext.mlDataTableProvider.customColumns[cellIndex.colIndex]
                            Text(column.title)
                                .font(.body.bold())
                            Text(column.rows[self.mlDataTableProviderContext.mlDataTableProvider.selectedRowIndex ?? 0])
                            SimulationController.MlDataTableProviderContext.EditValueView(customColumn: column, rowIndex: self.mlDataTableProvider.selectedRowIndex ?? 0, mlDataTableProvider: self.mlDataTableProvider, columnsDataModel: self.mlDataTableProviderContext.columnsDataModel)
                                .font(.callout)
                            Button("Apply") {
                                let featureValue =  self.mlDataTableProvider.valuesTableProvider?.predict(regressorName: "BoostedTreeRegressor", result:    self.mlDataTableProvider.mlRowDictionary)
                                $newPredictedValue.wrappedValue = featureValue?.featureValue(for: (self.mlDataTableProvider.valuesTableProvider?.targetColumn.name)!)?.doubleValue
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
