//
//  ModelsView.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 08.05.22.
//

import SwiftUI

struct ModelsView: View {
    @ObservedObject var model: Models
    @State var fileSelection: Files? = nil
    @State var mlSelection: String?
    var mlAlgorithms = ["MLLinearRegressor", "MLDecisionTreeRegressor", "MLRandomForestRegressor", "MLBoostedTreeRegressor"]
    var body: some View {
        VStack(alignment: .leading) {
            Text(model.name ?? "unbekanntes Model")
                .font(.title)
                .padding()
            HStack {
            Text("Files")
                .font(.title)
                .padding()
            Text("Algorithmus")
                    .font(.title)
                    .padding(.leading, 405)
            Text("Algorithmus KPI")
                    .font(.title)
                    .padding(.leading, 200)
            }
            VStack(alignment: .leading) {
                HStack {
                    List(ModelsModel.getFilesForItem(model: model), id: \.self, selection: $fileSelection) { file in
                        Text(file.name!)
                    }
                    .frame(width: 350, height: 100)
                    .padding()
                    VStack() {
                        Button("Lerne..") {
                            train(regressorName: mlSelection!)
                        }.padding()
                    }
                    List(mlAlgorithms, id: \.self, selection: $mlSelection) { algorithm in
                        Text(algorithm)
                    }.frame(width: 150)
                    
                }.padding(.trailing, 5)
                .frame(height: 100)
                if fileSelection != nil {
                    
                    HStack {
                        ForEach(ModelsModel.getColumnsForItem(model: model), id: \.self) { col in Text(col.name!)
                                .font(.body)
                                .frame(width: 80)
                                .padding(.trailing, 5)
                        }
                        Text("Prognose")
                            .font(.body)
                            .frame(width: 80)
                            .padding(.trailing, 5)
                        .frame(height: 50)
                    }.padding(.leading, 25)
                    
                    List {
                        ModelsModel.ValueRow(model: model, file: fileSelection!)
                    }.padding()
                }
            }
        }
    }
}
private func train(regressorName: String) {
    let trainer = Trainer()
    trainer.createModel(regressorName: regressorName)
}
struct ModelsView_Previews: PreviewProvider {
    static var previews: some View {
        ModelsView(model: ModelsModel().items[0])
    }
}
