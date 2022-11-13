//
//  CompositionView.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 06.11.22.
//

import SwiftUI
struct PredictionView: View {
    @ObservedObject var mlSimulationController: SimulationController
    @State var mlDataTableProviderContext: SimulationController.MlDataTableProviderContext!
    var predictionsDataModel = PredictionsModel()
    var prediction: Predictions?
    @State var composer: FileWeaver!
    @State var combinator: Combinator!
    @State var clusterSelection: PredictionsModel.predictionCluster?
    @State var valuesView: ValuesView?
    @State var gridItems = [GridItem]()
    @State var size: CGSize = .zero
    @State var headerSize: CGSize = .zero
    
    struct CellIndex: Identifiable {
        let id: Int
        let colIndex: Int
        let rowIndex: Int
    }
    init(prediction: Predictions?) {
        self.mlSimulationController = SimulationController()
        self.prediction = prediction
       
        
    }
    fileprivate func createGridItems() {
//        self.mlDataTableProviderContext!.mlDataTableProvider.mlColumns  = self.mlDataTableProvider.mergedColumns.map { $0.name!}
        self.mlDataTableProviderContext!.mlDataTableProvider.mlColumns!.forEach { col in
            let newGridItem = GridItem(.flexible(), spacing: 10, alignment: .trailing)
            self.gridItems.append(newGridItem)
        }
    }
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("Hello dear prediction").onAppear {
                guard let model = self.prediction!.prediction2model else {
                    fatalError()
                }
                self.mlDataTableProviderContext = SimulationController.returnFittingProviderContext(model: model)
                guard let mlDataTableProviderContext = mlDataTableProviderContext else {
                    fatalError()
                }
                guard let prediction = prediction else {
                    fatalError()
                }
                self.mlDataTableProviderContext.setPrediction(prediction: prediction)
                valuesView = ValuesView(mlDataTableProvider: mlDataTableProviderContext.mlDataTableProvider)
                createGridItems()
            }
            if self.mlDataTableProviderContext != nil {
                let cells = (0..<1).flatMap{j in self.mlDataTableProviderContext.mlDataTableProvider.customColumns.enumerated().map{(i,c) in CellIndex(id:j + i*1, colIndex:i, rowIndex:j)}}
                let gridItems = [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .trailing), GridItem(.flexible()),  GridItem(.flexible(), alignment: .trailing),  GridItem(.flexible()),  GridItem(.flexible(), alignment: .trailing)]
                ScrollView([.vertical], showsIndicators: true) {
                    LazyVGrid(columns: gridItems) {
                        ForEach(cells) { cellIndex in
                            let column = self.mlDataTableProviderContext.mlDataTableProvider.customColumns[cellIndex.colIndex]
//                                let fieldValue = Binding(
//                                    get: { Double.parse(from: column.rows[cellIndex.rowIndex].wrappedValue)! },
//                                    set: {
//                                        column.rows[cellIndex.rowIndex].wrappedValue = String($0)
//                                    }
//                                )
//                                TextField("number", value: fieldValue, formatter: NumberFormatter())
                            Text(column.title)
                                .font(.body.bold())
                                .onTapGesture {
                                    print(column.title)
                                }
                            Text("Wert")
                            Button("Apply") {
                                
                            }
                            .font(.callout)
                            Text("Wert 2")
                            Button("Apply") {
                                
                            }
                            .font(.callout)
                            Text("Wert 3")
//                            Text(column.rows[cellIndex.rowIndex])
//                                .padding(.horizontal)
//                                .font(.body).monospacedDigit()
//                                .scaledToFit()
//                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                }
                .padding()
                .background(.white)
            }
            Divider()
            valuesView
                .padding()
        }.padding()
    }
}
