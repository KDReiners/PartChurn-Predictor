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
    @ObservedObject var valueViewModel = ValuesModel()
    @State var mlSelection: String? = nil
    var mlAlgorithms = ["MLLinearRegressor", "MLDecisionTreeRegressor", "MLRandomForestRegressor", "MLBoostedTreeRegressor"]
    var mlTable: MLDataTable?
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
                        CompositionsView(model: model)
                    }
                    VStack(alignment: .leading) {
                        Text("Algorithmus")
                            .font(.title)
                        HStack {
                            List(mlAlgorithms, id: \.self, selection: $mlSelection) { algorithm in
                                Text(algorithm)
                            }.frame(width: 250)
                            VStack{
                                Button("Lerne..") {
                                    train(regressorName: mlSelection)
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
//                        AlgorithmsModel.valueList(model: model, file: fileSelection, algorithmName: mlSelection ?? "unbekannt")
                    }.padding()
                }
                Divider()
            }
            Spacer()
        }
    }
    private func fillFromCoreData() -> Void {
    }
    private func train(regressorName: String?) {
//        var trainer = Trainer(model: model, file: fileSelection)
//        guard let regressorNameWrapped = regressorName==nil ? mlAlgorithms.first : regressorName else {
//            return
//        }
//        mlSelection = regressorNameWrapped
//        trainer.createModel(regressorName: regressorNameWrapped, fileName: fileSelection?.name)
    }
}


struct ModelsView_Previews: PreviewProvider {
    static var previews: some View {
        ModelsView(model: ModelsModel().items[0], metric: Ml_MetricKPI(), mlTable: CoreDataML(model: ModelsModel().items[0]).mlDataTable)
    }
}
/// auxiliary views
public struct ModelListRow: View {
    public var selectedModel: Models
    public var editedModel: Binding<Models>?
    public var body: some View {
        Text("\(self.selectedModel.name ?? "(no name given)")")
    }
}
public struct EditableModelListRow: View {
    public var editedModel: Binding<Models>
    @State var name: String
    init(editedModel: Binding<Models>) {
        self.editedModel = editedModel
        self.name = editedModel.name.wrappedValue!
    }
    public var body: some View {
        TextField("Model Name", text: $name).onChange(of: name) { newValue in
            self.editedModel.name.wrappedValue = newValue
        }
    }
}
