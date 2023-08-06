////
////  ModelsView.swift
////  PartChurn Predictor
////
////  Created by Klaus-Dieter Reiners on 08.05.22.
////
//
import SwiftUI
import CreateML
public struct ModelListRow: View {
    @State private var fileNames: [String] = []
    @State var jsonFilesURL: URL!
    public var selectedModel: Models
    public var editedModel: Binding<Models>?
    init(selectedModel: Models, editedModel: Binding<Models>? = nil) {
        self.selectedModel = selectedModel
        self.editedModel = editedModel
    }
    public var body: some View {
        Text("\(self.selectedModel.name ?? "(no name given)")")
        VStack() {
            List(fileNames, id: \.self) { fileName in
                Text(fileName)
            }.onAppear {
                loadJSONFileNames()
            }
            Button("SQL Server Import") {
                let sqlHelper = SQLHelper()
                sqlHelper.runSQLCommand()
            }
        }
    }
    func loadJSONFileNames() {
        // Get the URL for the files directory
        jsonFilesURL = BaseServices.homePath.appendingPathComponent(selectedModel.name!).appendingPathComponent("Files", isDirectory: true)

        // Check if the directory exists
        if BaseServices.directoryExists(at: jsonFilesURL) {
            do {
                // Get the contents of the directory with the .json extension
                let fileURLs = try FileManager.default.contentsOfDirectory(at: jsonFilesURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)

                // Filter and keep only the .json file names
                fileNames = fileURLs.filter { $0.pathExtension == "json" }.map { $0.lastPathComponent }
            } catch {
                print("Error while loading file names: \(error)")
            }
        }
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
