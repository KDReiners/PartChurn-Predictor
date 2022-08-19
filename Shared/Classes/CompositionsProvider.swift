//
//  CompositionsViewProvider.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 17.08.22.
//

import Foundation
import CoreData
class CompositionsProvider: ObservableObject {
    var model: Models?
    var compositionEntries: Dictionary<String, [CompositionsViewEntry]>? {
        get {
            return fillCompositionViewEntries()
        }
    }
    var compositionsDataModel = CompositionsModel()
    var compositions: [Compositions] {
        get {
            
            return compositionsDataModel.items.filter { $0.composition2model == model}
        }
        
    }
    func fillCompositionViewEntries() -> Dictionary<String, [CompositionsViewEntry]>? {
        var result: Dictionary<String, [CompositionsViewEntry]>?
        var rawData: [CompositionsViewEntry]?
        for composition in compositions {
            rawData = rawData == nil ? [CompositionsViewEntry](): rawData
            let seriesDepth = Int16(composition.composition2timeseries?.timeseries2timeslices?.count ?? 0)
            let columnsDepth = Int16(composition.composition2columns?.count ?? 0)
            let groupPattern = "\(seriesDepth)" + "_" + "\(columnsDepth)"
            let entry = CompositionsViewEntry(composition: composition, seriesDepth: seriesDepth, columnsDepth: columnsDepth, groupPattern: groupPattern)
            rawData?.append(entry)
        }
        result = Dictionary(grouping: rawData!) { (entry) -> String in
            return entry.groupPattern
        }
        return result
    }
}
func sortWithKeys(_ dict: [String: [CompositionsViewEntry]]) -> [String:  [CompositionsViewEntry] ] {
    let sorted = dict.sorted(by: { $0.key < $1.key })
    var newDict: [String:  [CompositionsViewEntry]] = [:]
    for sortedDict in sorted {
        newDict[sortedDict.key] = sortedDict.value
    }
    return newDict
}
struct CompositionsViewEntry: Comparable {
    static func < (lhs: CompositionsViewEntry, rhs: CompositionsViewEntry) -> Bool {
        lhs.groupPattern == rhs.groupPattern
    }
    
    var composition: Compositions
    var seriesDepth: Int16
    var columnsDepth: Int16
    var groupPattern: String
}
