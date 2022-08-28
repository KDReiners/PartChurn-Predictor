//
//  ColumnsModel.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 06.05.22.
//

import Foundation
public class ColumnsModel: Model<Columns> {
    @Published var result: [Columns]!
    var model: Models?
    var filter: [Columns]?
    public init() {
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
    }
    public init(model: Models) {
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
        self.model = model
        
    }
    public init(columnsFilter: [Columns]) {
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
        self.filter = columnsFilter
    }
    override public var items: [Columns] {
        get {
            return filter == nil ? result: result.filter({ filter?.contains($0) == true })
        }
        set
        {
            result = newValue.sorted(by: { $1.orderno > $0.orderno })
        }
    }
    var timelessInputColumns: [Columns] {
        get {
            return self.items.filter { $0.ispartofprimarykey == 0 && $0.istimeseries == 0 && $0.ispartoftimeseries == 0 && $0.istarget == 0}
        }
    }
    var timedependantInputColums: [Columns] {
        get {
            return self.items.filter { $0.ispartofprimarykey == 0 &&  $0.istimeseries == 0 && $0.ispartoftimeseries == 1 && $0.istarget == 0}
        }
    }
    var targetColumns: [Columns] {
        get {
            return self.items.filter { $0.istarget == 1}
        }
    }
    
    var timelessTargetColumns: [Columns] {
        get {
            return self.items.filter { $0.ispartofprimarykey == 0 && $0.istimeseries == 0 && $0.ispartoftimeseries == 0 && $0.istarget == 1}
        }
    }
    
    var timedependantTargetColums: [Columns] {
        get {
            return self.items.filter { $0.ispartofprimarykey == 0 &&  $0.istimeseries == 0 && $0.ispartoftimeseries == 1 && $0.istarget == 1}
        }
    }
    
    var primaryKeyColum: Columns {
        get {
            return self.items.first(where: { $0.ispartofprimarykey == 1 })!
        }
    }
    var timeStampColumn: Columns {
        get {
            let result = self.items.filter { $0.istimeseries == 1}
            return result.first!
        }
    }
}
