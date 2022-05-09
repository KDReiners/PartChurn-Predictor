//
//  ModelsView.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 08.05.22.
//

import SwiftUI

struct ModelsView: View {
    @ObservedObject var model: Models
    @State var selection: Files? = nil
    var body: some View {
        VStack(alignment: .leading) {
            Text(model.name ?? "unbekanntes Model")
                .font(.title)
                .padding()
            Text("Files")
                .font(.title)
                .padding()
            HStack {
                List(ModelsModel.getFilesForItem(model: model), id: \.self, selection: $selection) { file in
                    Text(file.name!)
                }
                .frame(width: 350, height: 200)
                .padding()
                VStack() {
                    Button("Lerne..") {
                        predict(model: model, file: selection!)
                    }.padding()
                    Button("Trage Vorhersagen ein") {
                    }.padding()
                }
                
            }
            .frame(height: 200)
            HStack {
                ForEach(ModelsModel.getColumnsForItem(model: model), id: \.self) { col in Text(col.name!).font(.body).padding()
                }.padding()
            }
            if selection != nil {
                List {
                    ModelsModel.ValueRow(model: model, file: selection!)
                }
            }
        }
    }
}
private func predict(model: Models, file: Files) {
    var rows = ModelsModel.predictionRows(model: model, file: file)
    rows.getPrediction()
}
struct ModelsView_Previews: PreviewProvider {
    static var previews: some View {
        ModelsView(model: ModelsModel().items[0])
    }
}
