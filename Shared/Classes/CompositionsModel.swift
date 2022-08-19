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
    internal var hierarchy: [Cluster] {
        get {
            let timeSeriesDataModel = TimeSeriesModel()
//            let myItems = items.filter({$0.composition2model == model })
//            let item = myItems.first
            for item in items.filter({$0.composition2model == model }) {
            let seriesDepth = Int16(item.composition2timeseries?.timeseries2timeslices?.count ?? 0)
            let columnsDepth = Int16(item.composition2columns?.count ?? 0)
                let groupingPattern = "Col count \(columnsDepth)" + " TimeSlice count \(seriesDepth)"
                if !findCluster(groupingPattern: groupingPattern) {
                    let workCluster = Cluster()
                    workCluster.columns.append(contentsOf: ((item.composition2columns?.allObjects as? [Columns])!))
                    let timeSeries = timeSeriesDataModel.items.filter( { $0.timeseries2timeslices!.count == seriesDepth })
                    workCluster.timeSeries.append(contentsOf: timeSeries)
                    workCluster.groupingPattern = groupingPattern
                    arrayOfClusters.append(workCluster)
                }
            }
            return arrayOfClusters
        }
    }
    internal func findCluster(groupingPattern: String) -> Bool {
        var result = false
        let found: [Cluster] = arrayOfClusters.filter { $0.groupingPattern == groupingPattern }
        if found.count == 1 {
            result = true
        }
        if found.count > 1 {
            fatalError()
        }
       return result
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
        var timeSeries = [Timeseries]()
    }
    struct TimeeSeriesCluster: Identifiable {
        var id = UUID()
        var timeSeries: Timeseries
        var timeSlices: [Timeslices]
    }
}
