//
//  CompositionsModel.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 24.07.22.
//

import Foundation
public class CompositionsModel: Model<Compositions> {
    @Published var result: [Compositions]!
    @Published var arrayOfClusters = [CompositionCluster]()
    private var model: Models?
    public init() {
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
    }
    public init(model: Models) {
        self.model = model
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
    }
    override public var items: [Compositions] {
        get {
            return model == nil ? result: result.filter( {$0.composition2model == model})
        }
        set
        {
            
            result = newValue.sorted { (lhs, rhs) in
                if lhs.columnsdepth == rhs.columnsdepth { // <1>
                    return lhs.seriesdepth > rhs.seriesdepth
                }
                retrievePredictionClusters()
                return lhs.seriesdepth > rhs.seriesdepth // <2>
            }
             
        }
    }
    internal func seriesDepth(item: Compositions) -> Int {
        return item.composition2timeseries?.timeseries2timeslices?.count ?? 0
    }
    internal func retrievePredictionClusters() -> Void {
        for item in items.filter({$0.composition2model == model }) {
            mapCluster(composition: item)
        }
    }
    internal func mapCluster(composition: Compositions) -> Void {
        let seriesDepth = seriesDepth(item: composition)
        var cluster = self.arrayOfClusters.filter( {
            Set($0.columns) == composition.composition2columns as! Set<Columns>
            && seriesDepth == $0.seriesDepth
        }).first
        if cluster == nil {
            cluster = CompositionCluster()
            cluster!.columns.append(contentsOf: ((composition.composition2columns?.allObjects as? [Columns])!))
            let groupingPattern = "TimeSlices count \(seriesDepth)" + " Columns count \(composition.composition2columns!.count)"
            cluster?.groupingPattern = groupingPattern
            cluster?.timeSeries.append(composition.composition2timeseries!)
            cluster?.seriesDepth = Int32(seriesDepth)
            cluster?.compositions.append(composition)
            arrayOfClusters.append(cluster!)
        } else {
            cluster?.timeSeries.append(composition.composition2timeseries!)
            cluster?.compositions.append(composition)
        }
    }
        
    internal class CompositionCluster: Hashable {
        static func == (lhs: CompositionsModel.CompositionCluster, rhs: CompositionsModel.CompositionCluster) -> Bool {
            return lhs.id == rhs.id
        }
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        @Published var id = UUID()
        var compositions = [Compositions]()
        var groupingPattern: String?
        var columns = [Columns]()
        var seriesDepth: Int32!
        var timeSeries = [Timeseries]()
    }
}
