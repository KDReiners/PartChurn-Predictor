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
