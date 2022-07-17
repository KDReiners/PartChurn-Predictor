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
    internal func getCognitionType(file: Files) ->  BaseServices.cognitionTypes {
        var result: BaseServices.cognitionTypes = .cognitionError
        let fileColumns = getColumnsForFile(file: file)
        if fileColumns.filter({ $0.name?.uppercased() == "COGNITIONSOURCE" }).count > 0 && fileColumns.filter({ $0.name?.uppercased() == "COGNITIONOBJECT" }).count == 0 {
            result = .cognitionSource
        }
        if fileColumns.filter({ $0.name?.uppercased() == "COGNITIONSOURCE" }).count == 0 && fileColumns.filter({ $0.name?.uppercased() == "COGNITIONOBJECT" }).count > 0 {
            result = .cognitionObject
        }
        return result
    }
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
    private func getColumnsForFile(file: Files) -> [Columns] {
        let concreteFile = self.items.first(where: { $0 == file})
        return concreteFile?.file2columns?.allObjects as! [Columns]
    }
    
}
