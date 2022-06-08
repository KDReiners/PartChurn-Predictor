//
//  ModelsModel.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 06.05.22.
//

import Foundation
import SwiftUI
import CoreML
import CreateML
import TabularData

public class ModelsModel: Model<Models> {
    @Published var result: [Models]!
    public init() {
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
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
