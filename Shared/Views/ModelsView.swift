//
//  ModelsView.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 08.05.22.
//

import SwiftUI
import CreateML

struct ModelsView: View {
    @ObservedObject var model: Models
    @ObservedObject var metric: Ml_MetricKPI
    @State var fileSelection: Files? = nil
    @State var mlSelection: String? = nil
    var mlAlgorithms = ["MLLinearRegressor", "MLDecisionTreeRegressor", "MLRandomForestRegressor", "MLBoostedTreeRegressor"]
    let mlTable: MLDataTable
    
    var body: some View {
        HStack(spacing: 50) {
            VStack(alignment: .center) {
                Text(model.name ?? "unbekanntes Model")
                    .font(.title)
                    .padding(.top, 10)
                    .padding(.bottom, 5)
                Divider()
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
                            VStack{
                                Button("Lerne..") {
                                    train(regressorName: mlSelection!)
                                }.frame(width: 90)
                                Button("Core Data...") {
                                    fillFromCoreData()
                                }.frame(width: 90 )
                            }
                        }
                    }.padding()
                    VStack(alignment: .leading) {
                        Text("Algorithmus KPI")
                            .font(.title)
                        AlgorithmsModel.valueList(model: model, file: fileSelection, algorithmName: mlSelection ?? "unbekannt")
                    }.padding()
                }
                Divider()
                if fileSelection != nil {
                    ValuesModel.mlTableView(coreDataML: CoreDataML(model: model))
//                    ValuesModel.ContentView()
                    Divider()
                }
            }
            Spacer()
        }
        Spacer()
    }
    private func fillFromCoreData() -> Void {
    }
}
private func train(regressorName: String) {
    let trainer = Trainer()
    trainer.createModel(regressorName: regressorName)
}

struct ModelsView_Previews: PreviewProvider {
    static var previews: some View {
        ModelsView(model: ModelsModel().items[0], metric: Ml_MetricKPI(), mlTable: CoreDataML(model: ModelsModel().items[0]).baseData.mlDataTable!)
    }
}

