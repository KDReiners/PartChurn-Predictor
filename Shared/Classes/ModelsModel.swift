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
        var keys: [Int16]
        var valuesGrouped: [[Values]]
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
            self.keys = self.valueRows.sorted(by: { $0.key < $1.key}).map{$0.key}
            self.valuesGrouped = self.valueRows.sorted(by: { $0.key < $1.key}).map {$0.value}
        }
        public var body: some View {
            ForEach(self.keys.indices, id: \.self) { index in
                HStack {
//                    Text("\(keys[index])")
                    ForEach(0..<valuesGrouped[index].count, id: \.self) { col in
                        Text(valuesGrouped[index][col].value!)
                            .font(.body)
                            .frame(width: 80)
                    }
                    Text( "\(predict(valuesGrouped: valuesGrouped[index]))")
                        .font(.body)
                        .frame(width: 80)

                }
            }
        }
        func predict(valuesGrouped: [Values]) -> Double {
            var Kundennummer = ""
            var Kunde_seit: Double = 0
            var Account_Manager: String = ""
            var Anzahl_Arbeitsplaetze: Double = 0
            var Addison: Double = 0
            var Akte: Double = 0
            var SBS: Double = 0
            var Anzahl_UHD: Double = 0
            var davon_geloest: Double = 0
            var Jahresfaktura: Double = 0
            var Anzahl_OPPS: Double = 0
            var Digitalisierungsgrad: Double = 0
            for colIndex in 0..<valuesGrouped.count-1 {
                switch colIndex {
                case 0: Kundennummer = valuesGrouped[colIndex].value!
                case 1: Kunde_seit = Double(valuesGrouped[colIndex].value!)!
                case 2: Account_Manager = valuesGrouped[colIndex].value!
                case 3: Anzahl_Arbeitsplaetze = Double(valuesGrouped[colIndex].value!)!
                case 4: Addison = Double(valuesGrouped[colIndex].value!)!
                case 5: Akte = Double(valuesGrouped[colIndex].value!)!
                case 6: SBS = Double(valuesGrouped[colIndex].value!)!
                case 7: Anzahl_UHD = Double(valuesGrouped[colIndex].value!)!
                case 8: davon_geloest = Double(valuesGrouped[colIndex].value!)!
                case 9: Jahresfaktura = Double(valuesGrouped[colIndex].value!)!
                case 10: Anzahl_OPPS = Double(valuesGrouped[colIndex].value!)!
                case 11: Digitalisierungsgrad = Double(valuesGrouped[colIndex].value!)!
                default:
                    fatalError("Unexpected runtime error.")
                }
            }
            return ModelsModel.predict(Kunde_seit: Kunde_seit, Account_Manager: Account_Manager, Anzahl_Arbeitsplaetze: Anzahl_Arbeitsplaetze, ADDISON: Addison, AKTE: Akte, SBS: SBS, Anzahl_UHD: Anzahl_UHD, davon_geloest: davon_geloest, Jahresfaktura: Jahresfaktura, Anzahl_OPPs: Anzahl_OPPS, Digitalisierungsgrad: Digitalisierungsgrad)
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

    public static func predict( Kunde_seit: Double, Account_Manager: String, Anzahl_Arbeitsplaetze: Double, ADDISON: Double, AKTE: Double, SBS: Double, Anzahl_UHD: Double, davon_geloest: Double, Jahresfaktura: Double, Anzahl_OPPs: Double, Digitalisierungsgrad: Double) -> Double {
        let model = MarsHabitatPricer()
        guard let ChurnPredicter = try? model.prediction(Kunde_seit: Kunde_seit, Account_Manager: Account_Manager, Anzahl_Arbeitsplaetze: Anzahl_Arbeitsplaetze, ADDISON: ADDISON, AKTE: AKTE, SBS: SBS, Anzahl_UHD: Anzahl_UHD, davon_geloest: davon_geloest, Jahresfaktura: Jahresfaktura, Anzahl_OPPs: Anzahl_OPPs, Digitalisierungsgrad: Digitalisierungsgrad) else {
            fatalError("Unexpected runtime error.")
        }
        return ChurnPredicter.Kuendigt
    }
}
