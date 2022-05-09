//
//  ModelsModel.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 06.05.22.
//

import Foundation
import SwiftUI
public class ModelsModel: Model<Models> {
    @Published var result: [Models]!
    public init() {
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
    }
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
    public struct ValueRow: View {
        var model: Models? = nil
        var file: Files? = nil
        var columns: [Columns]? = nil
        var values: [Values]
        var recordCount: Int = 0
        var valueRows: Dictionary<Int16, [Values]>
        init(model: Models, file: Files) {
            self.model = model
            self.file = file
            self.columns = ModelsModel.getColumnsForItem(model: model)
            self.values = ValuesModel().items.filter( {
                return $0.value2model == model }).sorted(by:   {$0.rowno < $1.rowno},
                      { $0.value2column!.orderno < $1.value2column!.orderno }
            )
            self.recordCount = ValuesModel().recordCount(model: model)
            self.valueRows = Dictionary(grouping: self.values) { (value) -> Int16 in
                return value.rowno}
        }
        public var body: some View {
            let keys = self.valueRows.sorted(by: { $0.key < $1.key}).map{$0.key}
            let values = self.valueRows.sorted(by: { $0.key < $1.key}).map {$0.value}
            ForEach(keys.indices, id: \.self) { index in
                HStack {
//                    Text("\(keys[index])")
                    ForEach(0..<values[index].count, id: \.self) { col in
                        Text(values[index][col].value!)
                            .font(.body)
                            .padding()
                    }

                }
            }
        }
    }
    public static func getFilesForItem(model: Models) -> [Files] {
        let files = FilesModel()
        return files.items.filter( { $0.files2model == model } )
    }
    public static func getColumnsForItem(model: Models) -> [Columns] {
        let columuns = ColumnsModel()
        return columuns.items.filter( { $0.column2model == model} ).sorted(by: { $0.orderno < $1.orderno})
    }
    override public var items: [Models] {
        get {
            return result
        }
        set
        {
            result = newValue.sorted(by: { $1.name ?? "" > $0.name ?? ""})
        }
    }
    
}
