//
//  PredictionsModel.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 22.08.22.
//

import Foundation
import CoreData
import TabularData
public class PredictionsModel: Model<Predictions> {
    @Published var result: [Predictions]!
    @Published var arrayOfPredictions = [predictionCluster]()
    @Published var timeSeriesSelections = [String]()
    private var model: Models?
    private var compositionsDataModel: CompositionsModel?
    public init() {
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
    }
    public init(model: Models) {
        self.model = model
        let readOnlyFields: [String] = []
        super.init(readOnlyFields: readOnlyFields)
    }
    override public var items: [Predictions] {
        get {
            return result
        }
        set
        {
            result = newValue.sorted { (lhs, rhs) in
                if lhs.columnsdepth == rhs.columnsdepth { // <1>
                    return lhs.seriesdepth > rhs.seriesdepth
                }
                return lhs.seriesdepth < rhs.seriesdepth // <2>
            }
        }
    }
    internal func includedColumns(prediction: Predictions) -> [Columns] {
        var includedColumns = [Columns]()
        guard let foundPrediction = self.items.first(where: {$0 == prediction }) else { return includedColumns}
        guard let foundComposition = (foundPrediction.prediction2compositions?.allObjects.first as? Compositions) else { return  includedColumns }
        guard let columns = (foundComposition.composition2columns?.allObjects as? [Columns]) else { return includedColumns }
        guard let timeSeriesColumn = (prediction.prediction2model?.model2columns?.allObjects as? [Columns])?.filter( { $0.istimeseries == 1}).first else { return includedColumns}
        guard let targetColumns = (prediction.prediction2model?.model2columns?.allObjects as? [Columns])?.filter( {$0.istarget == 1 && $0.ispartoftimeseries == 1}) else { return includedColumns}
        includedColumns.append(contentsOf: columns.filter({$0.istimeseries == 0 && $0.isshown == 1 && $0.ispartofprimarykey == 0}).sorted(by: {$0.name! < $1.name!}))
        includedColumns.append(contentsOf: targetColumns)
        includedColumns.append(timeSeriesColumn)
        return includedColumns
    }
    internal func savePredictions(model: Models) {
        getCurrentCombinations(model: model)
        for cluster in compositionsDataModel!.arrayOfClusters {
            let newPrediction = self.insertRecord()
            newPrediction.id = UUID()
            newPrediction.groupingpattern = cluster.groupingPattern
            newPrediction.seriesdepth = Int16(cluster.seriesDepth)
            newPrediction.columnsdepth = Int16(cluster.columns.count)
            newPrediction.prediction2model = model
            for composition in cluster.compositions {
                
                composition.composition2predictions = newPrediction
            }
        }
        BaseServices.save()
    }
    private func getCurrentCombinations(model: Models) {
        self.model = model
        compositionsDataModel =  CompositionsModel(model: model)
        compositionsDataModel?.retrievePredictionClusters()
    }
    internal func createPredictionForModel(model: Models) {
//      self.deleteAllRecords(predicate: nil)
        self.model = model
        let foundItems = self.items.filter( { $0.prediction2model == model })
        for item in foundItems {
            let newPredictionPresenatation = predictionCluster()
            newPredictionPresenatation.prediction = item
            newPredictionPresenatation.id = item.id!
            newPredictionPresenatation.groupingPattern = item.groupingpattern
            newPredictionPresenatation.seriesDepth = Int16(item.seriesdepth)
            newPredictionPresenatation.columnsDepth = Int16(item.columnsdepth)
            let composition = (item.prediction2compositions!.allObjects.first as! Compositions)
            newPredictionPresenatation.columns.append(contentsOf: composition.composition2columns?.allObjects as! [Columns])
            for composition in item.prediction2compositions!.allObjects as! [Compositions] {
//                newPredictionPresenatation.columns.append(contentsOf: composition.composition2columns?.allObjects as! [Columns])
                newPredictionPresenatation.timeSeries.append(composition.composition2timeseries!)
            }
            arrayOfPredictions.append(newPredictionPresenatation)
        }
    }
    internal func getTimeSeries() {
        for prediction in arrayOfPredictions {
            self.timeSeriesSelections.append(prediction.timeSeries.map( { String($0.from)}).joined(separator: ", "))
        }
    }
    internal class predictionCluster: CompositionsModel.Cluster {
        var columnsDepth: Int16!
        var prediction: Predictions!
        var connectedTimeSeries: [String] {
            get {
                var result = [String]()
                for series in self.timeSeries.sorted(by: { $0.from < $1.from }) {
                    let test = (series.timeseries2timeslices?.allObjects as! [Timeslices]).sorted(by: { $0.value < $1.value }).map( {String($0.value)}).joined(separator: ", ")
                    result.append(test)
                }
                return result
            }
        }
    }
}
