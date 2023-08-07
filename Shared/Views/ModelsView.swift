import SwiftUI
import CoreData

public struct ModelsView: View {
    @ObservedObject var filesDataModel = FilesModel()
    @State var files: [Files]?
    @State var selectedFilenames: Set<String> = Set<String>()
    @State private var showAddFileView = false
    public var selectedModel: Models
    
    init(selectedModel: Models) {
        self.selectedModel = selectedModel
    }

    public var body: some View {

            List{
                VStack(spacing: 16) {
                    if let files = files {
                        ForEach(0..<files.count, id: \.self) { index in
                            HStack {
                                    if index < files.count {
                                        TableViewRow(file: files[index], isSelected: selectedFilenames.contains(files[index].name ?? "")) {
                                            if selectedFilenames.contains(files[index].name ?? "") {
                                                selectedFilenames.remove(files[index].name ?? "")
                                            } else {
                                                selectedFilenames.insert(files[index].name ?? "")
                                            }
                                        }
                                    } else {
                                        Spacer()
                                    }
                                }
                            
                        }
                    }
                    // Button to show the AddFileView
                    HStack(alignment: .center, spacing: 10) {
                        Button("+") {
                            addNewFile(newFilename: "unknown Filename")
                        }
                        Button("-") {
                            for filename in selectedFilenames {
                                let obsoleteFile = filesDataModel.items.filter { $0.name == filename}.first
                                selectedFilenames.remove((obsoleteFile?.name)!)
                                filesDataModel.deleteRecord(record: obsoleteFile!)
                                BaseServices.save()
                                loadJSONFileNames()
                            }
                        }
                        .disabled(selectedFilenames.count == 0)
                    }
                }
                .padding()
            }
            .onAppear {
                loadJSONFileNames()
            }
        }

    func loadJSONFileNames() {
        // Fetch the files associated with the selected model from Core Data
        files = FilesModel().items.filter( { $0.files2model == selectedModel })
    }

    func addNewFile(newFilename: String) {
        let newFile = filesDataModel.insertRecord()
        newFile.files2model = selectedModel
        newFile.name = newFilename
        files?.append(newFile)
        BaseServices.save()
    }
}

struct TableViewRow: View {
    var file: Files
    var isSelected: Bool
    var toggleSelection: () -> Void

    var body: some View {
        HStack {
            Toggle(isOn: Binding(
                            get: { isSelected },
                            set: { isSelected in
                                toggleSelection() // Call the toggleSelection closure when the checkbox state changes
                            }
                        )) {
                            EmptyView() // Use EmptyView to hide the label for the Toggle
                        }
                        .toggleStyle(CheckboxToggleStyle()) // Use SwitchToggleStyle for a checkbox appearance
            TextField("SQL Command", text: Binding(
                get: { file.sqlCommand ?? "" },
                set: { newValue in
                    file.sqlCommand = newValue
                    BaseServices.save()
                })
            )
            .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("File Name", text: Binding(
                get: { file.name ?? "" },
                set: { newValue in
                    file.name = newValue
                    BaseServices.save()
                })
            )
            .textFieldStyle(RoundedBorderTextFieldStyle())
            Text("\(file.lastupdatedate ?? Date(), formatter: BaseServices.standardDateFormatter)")

        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.3) : Color.clear) // Highlight the selected rows with a blue background
        .cornerRadius(8)
        .onTapGesture(perform: toggleSelection)
    }

}

