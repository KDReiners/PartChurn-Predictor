//
//  ModelsView.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 08.05.22.
//

import SwiftUI

struct ModelsView: View {
    @ObservedObject var model: Models
    @ObservedObject var metric: Ml_MetricKPI
    @State var fileSelection: Files? = nil
    @State var mlSelection: String? = nil
    var mlAlgorithms = ["MLLinearRegressor", "MLDecisionTreeRegressor", "MLRandomForestRegressor", "MLBoostedTreeRegressor"]
    
    var body: some View {
        HStack(spacing: 50) {
            VStack(alignment: .leading) {
                Text(model.name ?? "unbekanntes Model")
                    .font(.title)
                    .padding()
                Spacer()
                HStack {
                    VStack(alignment: .leading) {
                        Text("Files")
                            .font(.title)
                        List(ModelsModel.getFilesForItem(model: model), id: \.self, selection: $fileSelection) { file in
                            Text(file.name!)
                                .font(.body)
                        }
                    }.padding()
                    VStack(alignment: .leading) {
                        Text("Algorithmus")
                            .font(.title)
                        HStack {
                            List(mlAlgorithms, id: \.self, selection: $mlSelection) { algorithm in 
                                Text(algorithm)
                            }.frame(width: 250)
                            Button("Lerne..") {
                                train(regressorName: mlSelection!)
                            }.frame(width: 60)
                        }
                    }.padding()
                    VStack(alignment: .leading) {
                        Text("Algorithmus KPI")
                            .font(.title)
                        Spacer()
                        AlgorithmsModel.valueList(model: model, file: fileSelection, algorithmName: mlSelection ?? "unbekannt")
                    }
                    
                }
                Divider()
                if fileSelection != nil {
                    VStack(alignment: .leading) {
                        HStack {
                            ForEach(ModelsModel.getColumnsForItem(model: model), id: \.self) { col in Text(col.name!)
                                    .font(.body)
                                    .frame(width: 80)
                            }
                            Text("Prognose")
                                .font(.body)
                        }
                        
                        List {
                            ModelsModel.ValueRow(model: model, file: fileSelection!)
                        }
                    }.padding()
                }
            }
            Spacer()
        }
        Spacer()
    }
}
private func train(regressorName: String) {
    let trainer = Trainer()
    trainer.createModel(regressorName: regressorName)
}
struct ModelsView_Previews: PreviewProvider {
    static var previews: some View {
        ModelsView(model: ModelsModel().items[0], metric: Ml_MetricKPI())
    }
}
