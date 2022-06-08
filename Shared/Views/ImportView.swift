//
//  ImportView.swift
//  healthKitShaman
//
//  Created by Klaus-Dieter Reiners on 14.12.21.
//

import SwiftUI

struct ImportView: View {
    @ObservedObject var modelsView = ModelsModel()
    @State var editingMode = false
    @State var selection: Models? = nil
    @State var filename = "Filename"
    @State var url: URL!
    @State var showFileChooser = false
    var demoData = ["Phil Swanson"]
    @ViewBuilder
    var body: some View {
        VStack(alignment: .trailing) {
            HStack {
                List($modelsView.items, id: \.self, selection: $selection) { model in
                    switch editingMode {
                    case true:
                        EditableModelListRow(editedModel: model).onSubmit {
                            modelsView.saveChanges()
                            editingMode = false
                        }
                    case false:
                        ModelListRow(selectedModel: model.wrappedValue).onTapGesture(count: 2) {
                            editingMode = true
                        }
                    }
                }.onTapGesture(count: 2) {
                    editingMode.toggle()
                }
            }.padding()
            Divider()
            HStack(alignment: .center, spacing: 10) {
                Button("Add Model") {
                    let newModel = modelsView.insertRecord()
                    newModel.name = "Neues Modell"
                    modelsView.saveChanges()
                }
                Button("Delete Model") {
                    modelsView.deleteRecord(record: $selection.wrappedValue!)
                }
            }.padding()
            Divider()
            HStack(alignment: .center, spacing: 10) {
                Text(filename).frame(width: 400).border(.blue).background(.white)
                Button("select File") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    if panel.runModal() == .OK {
                        self.filename = panel.url?.lastPathComponent ?? "None"
                        self.url = panel.url
                    }
                }
                Button("Import") {
                    CSV_Importer.read(url: self.url, modelName: (selection?.name)!)
                }
            }.padding()
        }
    }
}

struct ImportView_Previews: PreviewProvider {
    static var previews: some View {
        ImportView()
    }
}
