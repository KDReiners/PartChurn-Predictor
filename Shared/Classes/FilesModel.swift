//
//  FilesModel.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 07.05.22.
//

import Foundation
//
//  ColumnsModel.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 06.05.22.
//

import Foundation
public class FilesModel: Model<Files> {
    @Published var result: [Files]!
    public init() {
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
    }
    override public var items: [Files] {
        get {
            return result
        }
        set
        {
            result = newValue.sorted(by: { $1.name ?? "" > $0.name ?? ""})
        }
    }
    
}
