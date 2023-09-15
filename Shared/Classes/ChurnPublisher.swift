//
//  ChurnPublisher.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 27.08.23.
//

import Foundation
import CreateML
import CoreML
import CoreData

class ChurnPublisher: Identifiable {
    var model: Models
    var predictions: [Predictions]!
    var timeSliceToStartFrom: Timeslices!
    init(model: Models)
    {
        self.model = model
        guard let observation = (model.model2observations?.allObjects as? [Observations])?.first else {
            return
        }
        guard let timeSliceToStopLearning = model.model2lastlearningtimeslice else {
            return
        }
        guard let predictions = model.model2predictions?.allObjects as? [Predictions] else {
            return
        }
        self.timeSliceToStartFrom  = timeSliceToStopLearning
        self.predictions = predictions
//        calculate()
    }
    /// Ich habe für jede prediction eine BasisTabelle mit t = 0
    /// Ich ermittle den Minority Target Wert
    /// jetzt verwende ich alle lookeads, die zu der jeweiligen Prediction gehören
    /// und berechne:
    ///     - wie gut haben sie den Zeiten < timeSlicetoStartfrom vorhergesagt
    ///     - wie gut für die Zeiten >= timeSliceToStartFrom
    func calculate() {
        var i = 0
        let columnsDataModel = ColumnsModel(model: self.model)
        guard let primaryKeyColumn = columnsDataModel.primaryKeyColumn else {
            print("calculate needs a primary key columns")
            return
        }
        guard let timeStampColumn = columnsDataModel.timeStampColumn else {
            print("calculate needs a timeStamp columns")
            return
        }
        let predictionsDataModel = PredictionsModel(model: self.model)
        guard let extractionTimeSliceFrom = model.model2lastlearningtimeslice  else {
            print ("no timeslice found to begin extraction with")
            return
        }
        predictions.forEach { prediction in
            predictionsDataModel.createPredictionForModel(model: self.model)
            let cluster = predictionsDataModel.arrayOfPredictions.filter { $0.prediction == prediction}.first
            let lookAheadItems = prediction.prediction2lookaheads?.allObjects as! [Lookaheads]
            for algorithm in prediction.prediction2algorithms?.allObjects as![Algorithms] {
                for lookAheadItem in lookAheadItems {
                    if LookaheadsModel.LookAheadItemRelations(lookAheadItem: lookAheadItem).connectedAlgorihms .contains(algorithm) {
                        let dataContext = SimulationController.returnFittingProviderContext(model: self.model, lookAhead: Int(lookAheadItem.lookahead))
                        if cluster?.connectedTimeSeries != nil {
                            dataContext?.mlDataTableProvider.timeSeries = cluster?.selectedTimeSeries
                        } else {
                            dataContext?.mlDataTableProvider.timeSeries = nil
                        }
                        dataContext?.mlDataTableProvider.mlDataTable = dataContext!.composer?.mlDataTable_Base
                        dataContext?.mlDataTableProvider.orderedColumns = dataContext!.composer?.orderedColumns!
                        dataContext!.mlDataTableProvider.selectedColumns = cluster?.columns
                        dataContext!.mlDataTableProvider.prediction = prediction
                        dataContext?.mlDataTableProvider.mlDataTable = try! dataContext!.mlDataTableProvider.buildMlDataTable(lookAhead: Int(lookAheadItem.lookahead)).mlDataTable
                        dataContext?.mlDataTableProvider.regressorName = algorithm.name!
                        guard let predictionTable = dataContext?.mlDataTableProvider.mlDataTable else {
                            return
                        }
                        guard let orderedColumns = dataContext?.mlDataTableProvider.orderedColumns else {
                            return
                        }
                        guard let selectedColumns = dataContext?.mlDataTableProvider.selectedColumns else {
                            return
                        }
                        guard let algorithmName = algorithm.name else {
                            return
                        }
                        guard let timeStampColumn = columnsDataModel.timeStampColumn else {
                            return
                        }
                        print("working on prediction \(prediction.groupingpattern ?? "no grouping pattern found") for algorithm: \(algorithm.name ?? "no Algorithm selected") with lookAhead: \(lookAheadItem.lookahead)")
                        let lookAhead = Int(lookAheadItem.lookahead)
                        let predictionProvider = PredictionsProvider(mlDataTable: predictionTable, orderedColNames: orderedColumns.map( { $0.name! }), selectedColumns: selectedColumns, prediction: prediction, regressorName: algorithmName, lookAhead: lookAhead)
                        let result = predictionProvider.mlDataTable
                        let distinctTimeStamps = Array(result[timeStampColumn.name!].ints!).reduce(into: Set<Int>()) { $0.insert($1) }.sorted(by: { $0 < $1})
                        for i in 0..<distinctTimeStamps.filter( {$0 > extractionTimeSliceFrom.value }).count {
                            let mask = result[timeStampColumn.name!] == distinctTimeStamps[i]
                            dataContext?.mlDataTableProvider.mlDataTableRaw = result[mask]
                            dataContext?.mlDataTableProvider.mlDataTable = result[mask]
                            dataContext?.mlDataTableProvider.syncUpdateTableProvider(callingFunction: #function, className: "ChurnPublisher", lookAhead: lookAhead)
                            print("ready")
                        }
                    }
                }
                break
            }
            
        }
    }
}
