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
    var columnsDataModel: ColumnsModel
    var timeSliceToStopLearning: Timeslices!
    var timeSlicesDataModel: TimeSlicesModel
    init(model: Models)
    {
        self.model = model
        self.timeSlicesDataModel = TimeSlicesModel()
        self.columnsDataModel = ColumnsModel(model: self.model)
        guard let timeSliceToStopLearning = model.model2lastlearningtimeslice else {
            return
        }
        self.timeSliceToStopLearning = timeSliceToStopLearning
        guard let predictions = model.model2predictions?.allObjects as? [Predictions] else {
            return
        }
        self.predictions = predictions
        //        calculate()
    }
    func calculate() {
        let columnsDataModel = ColumnsModel(model: self.model)
        let predictionsDataModel = PredictionsModel(model: self.model)
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
                        let mask = result[timeStampColumn.name!] > Int((model.model2lastlearningtimeslice?.value)!)
                        dataContext?.mlDataTableProvider.mlDataTableRaw = result[mask]
                        dataContext?.mlDataTableProvider.mlDataTable = result[mask]
                        let timeSliceFrom = timeSlicesDataModel.getTimeSlice(timeSliceInt: (dataContext?.mlDataTableProvider.distinctTimeStamps?.first)!)
                        let timeSliceTo = timeSlicesDataModel.getTimeSlice(timeSliceInt: (dataContext?.mlDataTableProvider.distinctTimeStamps?.last)!)
                        dataContext?.mlDataTableProvider.syncUpdateTableProvider(callingFunction: #function, className: "ChurnPublisher", lookAhead: lookAhead)
                        let observation = ObservationsModel().items.filter( { $0.observation2prediction == prediction && $0.observation2lookahead == lookAheadItem && $0.observation2timeslicefrom == timeSliceFrom && $0.observation2timesliceto == timeSliceTo} ).first
                        store2Comparisons(dataContext: dataContext, observation: observation)
                        
                        
                    }
                }
                break
            }
            
        }
    }
    func store2Comparisons(dataContext: SimulationController.MlDataTableProviderContext?, observation: Observations?) {
        let entryDate = getCurrentDate()
        let comparisonDataModel = ComparisonsModel(model: model)
        let metricValues = observation?.observation2predictionmetricvalues?.allObjects as! [Predictionmetricvalues]
        let threshold = metricValues.filter( { $0.predictionmetricvalue2predictionmetric?.name == "predictionValueAtThreshold"})
//        comparisonDataModel.deleteAllRecords(predicate: nil)
        guard let primaryKeyColumn = self.columnsDataModel.primaryKeyColumn else {
            print("\(#function) needs a primary key columns")
            return
        }
        guard let timeStampColumn = columnsDataModel.timeStampColumn else {
            print("\(#function) needs a timeStamp columns")
            return
        }
        guard let targetColumn = columnsDataModel.targetColumns.first else {
            print("\(#function) needs a target columns")
            return
        }
        guard let dataContext = dataContext else {
            print("\(#function) need a datacontext")
            return
        }
        guard let observation = observation else {
            print("\(#function) need an observation")
            return
        }
        let predictedColumnName = "Predicted: " + targetColumn.name!
        
        dataContext.mlDataTableProvider.mlDataTable.rows.forEach { row in
//            if row["S_CUSTNO"]?.stringValue == "1010180" {
                let comparison = comparisonDataModel.insertRecord()
                comparison.comparisondate = entryDate
                comparison.comparison2observaton = observation
                let sourcePrimaryKeyColumn = dataContext.mlDataTableProvider.mlDataTable[primaryKeyColumn.name!]
                switch  sourcePrimaryKeyColumn.type {
                case .int :
                    comparison.primarykey = String(row[primaryKeyColumn.name!]?.intValue! ?? 0)
                case .double :
                    comparison.primarykey = String(row[primaryKeyColumn.name!]?.doubleValue! ?? 0)
                case .string:
                    comparison.primarykey = String(row[primaryKeyColumn.name!]?.stringValue! ?? "")
                default:
                    fatalError("\(#function) cannot determine type.")
                }
                comparison.timebase = Int16(row[timeStampColumn.name!]?.intValue ?? 0)
                comparison.targetreported = Int32((row[targetColumn.name!]?.intValue)!)
                comparison.targetpredicted = (row[predictedColumnName]?.doubleValue)!
                comparison.comparison2observaton = observation
                comparison.comparion2model = model
            }
            BaseServices.save()
//        }
    }
    func getCurrentDate() -> Date {
        // Get the current date and time
        let currentDate = Date()
        
        // Create a Calendar instance
        let calendar = Calendar.current
        
        // Get the date components (year, month, day) from the current date
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)
        
        // Create a new Date instance from the date components
        guard let dateWithoutTime = calendar.date(from: dateComponents) else {
            fatalError("cannot convert date")
        }
        return dateWithoutTime
        
    }
}
