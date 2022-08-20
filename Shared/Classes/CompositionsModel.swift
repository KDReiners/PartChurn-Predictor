//
//  CompositionsModel.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 24.07.22.
//

import Foundation
public class CompositionsModel: Model<Compositions> {
    @Published var result: [Compositions]!
    @Published var arrayOfClusters = [Cluster]()
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
            return result
        }
        set
        {
            
            result = newValue.sorted { (lhs, rhs) in
                if lhs.seriesdepth == rhs.seriesdepth { // <1>
                    return lhs.columnsdepth > rhs.columnsdepth
                }
                return lhs.columnsdepth > rhs.columnsdepth // <2>
            }
             
        }
    }
    internal func seriesDepth(item: Compositions) -> Int {
        return item.composition2timeseries?.timeseries2timeslices?.count ?? 0
    }
    internal var hierarchy: [Cluster] {
        get {

            for item in items.filter({$0.composition2model == model }) {
                mapCluster(composition: item)
            }
            return arrayOfClusters
        }
    }
    internal func mapCluster(composition: Compositions) -> Void {
        let seriesDepth = seriesDepth(item: composition)
        var cluster = self.arrayOfClusters.filter( {
            Set($0.columns) == composition.composition2columns as! Set<Columns>
            && seriesDepth == $0.seriesDepth
        }).first
        if cluster == nil {
            cluster = Cluster()
            cluster!.columns.append(contentsOf: ((composition.composition2columns?.allObjects as? [Columns])!))
            let groupingPattern = "Col count \(composition.composition2columns!.count)" + " TimeSlice count \(seriesDepth)"
            cluster?.groupingPattern = groupingPattern
            cluster?.timeSeries.append(composition.composition2timeseries!)
            cluster?.seriesDepth = seriesDepth
            arrayOfClusters.append(cluster!)
        } else {
            cluster!.timeSeries.append(composition.composition2timeseries!)
        }
    }
        
    internal class Cluster: Hashable {
        static func == (lhs: CompositionsModel.Cluster, rhs: CompositionsModel.Cluster) -> Bool {
            return lhs.id == rhs.id
        }
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        @Published var id = UUID()
        var compositions: [Compositions]?
        var groupingPattern: String?
        var columns = [Columns]()
        var seriesDepth: Int!
        var timeSeries = [Timeseries]()
    }
    struct TimeeSeriesCluster: Identifiable {
        var id = UUID()
        var timeSeries: Timeseries
        var timeSlices: [Timeslices]
    }
}
