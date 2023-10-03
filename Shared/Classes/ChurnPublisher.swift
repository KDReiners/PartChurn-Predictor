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
    var comparisonsDataModel: ComparisonsModel!
    init(model: Models, completion: @escaping () -> Void)  {
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
    init(model: Models )
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
    func cleanUp(comparisonsDataModel: ComparisonsModel) {
        self.comparisonsDataModel = comparisonsDataModel
        comparisonsDataModel.deleteAllRecords(predicate: nil)
        comparisonsDataModel.reportingSummaries.removeAll()
        comparisonsDataModel.reportingDetails.removeAll()
        comparisonsDataModel.votings.removeAll()
    }
    func calculate(comparisonsDataModel: ComparisonsModel) async {
        let predictionsDataModel = PredictionsModel(model: self.model)
        let observations = ObservationsModel().items.filter( { $0.observation2model == self.model && $0.observation2timeslicefrom!.value < self.model.model2lastlearningtimeslice!.value})
        observations.forEach { observation in
            guard let prediction = observation.observation2prediction else {
                print("\(#function) cannot create prediction.")
                return
            }
            let cluster = predictionsDataModel.createPredictionCluster(item: prediction)
            guard let lookAheadItem = observation.observation2lookahead else {
                print("\(#function) cannot create lookAhead Item.")
                return
            }
            for algorithm in prediction.prediction2algorithms?.allObjects as![Algorithms] {
                guard let baseTargetStatistics = predictionsDataModel.getTargetStatistics(observation: observation, algorithm: algorithm) else {
                    continue
                }
                if LookaheadsModel.LookAheadItemRelations(lookAheadItem: lookAheadItem).connectedAlgorihms .contains(algorithm) {
                    let dataContext = SimulationController.returnFittingProviderContext(model: self.model, lookAhead: Int(lookAheadItem.lookahead))
                    if cluster.connectedTimeSeries != nil {
                        dataContext?.mlDataTableProvider.timeSeries = cluster.selectedTimeSeries
                    } else {
                        dataContext?.mlDataTableProvider.timeSeries = nil
                    }
                    dataContext?.mlDataTableProvider.mlDataTable = dataContext!.composer?.mlDataTable_Base
                    dataContext?.mlDataTableProvider.orderedColumns = dataContext!.composer?.orderedColumns!
                    dataContext!.mlDataTableProvider.selectedColumns = cluster.columns
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
                    let lookAhead = Int(lookAheadItem.lookahead)
                    let predictionProvider = PredictionsProvider(mlDataTable: predictionTable, orderedColNames: orderedColumns.map( { $0.name! }), selectedColumns: selectedColumns, prediction: prediction, regressorName: algorithmName, lookAhead: lookAhead)
                    let result = predictionProvider.mlDataTable
                    let mask = result[timeStampColumn.name!] > Int((model.model2lastlearningtimeslice?.value)!)
                    dataContext?.mlDataTableProvider.mlDataTableRaw = result[mask]
                    dataContext?.mlDataTableProvider.mlDataTable = result[mask]
                    dataContext?.mlDataTableProvider.syncUpdateTableProvider(callingFunction: #function, className: "ChurnPublisher", lookAhead: lookAhead)
                    guard let targetStatistics = dataContext?.mlDataTableProvider.tableStatistics?.targetStatistics.first  else {
                        continue
                    }
                    store2Comparisons(dataContext: dataContext, observation: observation, targetStatistics: targetStatistics, baseTargetStatistics: baseTargetStatistics)
                }
                break
            }
        }
    }
    func store2Comparisons(dataContext: SimulationController.MlDataTableProviderContext?, observation: Observations?, targetStatistics: MlDataTableProvider.TargetStatistics, baseTargetStatistics: MlDataTableProvider.TargetStatistics) {
        let entryDate = getCurrentDate()
        guard let observationID = observation?.objectID else {
            print("\(#function) no Observation is passed.")
            return
        }
        let localPredictionKPI = PredictionKPI(targetStatistic: baseTargetStatistics)
        if Double(localPredictionKPI.predictionValueAtOptimum) == 0.00 {
            return
        }
        let modelID = self.model.objectID
        let metricValues = observation?.observation2predictionmetricvalues?.allObjects as! [Predictionmetricvalues]
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
        let predictedColumnName = "Predicted: " + targetColumn.name!
        let privateContext = PersistenceController.shared.container.newBackgroundContext()
        privateContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        privateContext.perform {
            let mask = dataContext.mlDataTableProvider.mlDataTable[predictedColumnName] <= Double(localPredictionKPI.predictionValueAtThreshold)!
            let observationInPrivateContext = privateContext.object(with: observationID) as? Observations
            let modelInPrivateContext = privateContext.object(with: modelID) as? Models
            dataContext.mlDataTableProvider.mlDataTable[mask].rows.forEach { row in
                let comparison = NSEntityDescription.insertNewObject(forEntityName: Comparisons.entity().name!, into: privateContext) as! Comparisons
                comparison.comparisondate = entryDate
                comparison.comparison2observation = observationInPrivateContext
                comparison.comparion2model = modelInPrivateContext
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
                
            }
            do {
                try privateContext.save()
                // Merge the changes with the main context if needed
                PersistenceController.shared.container.viewContext.performAndWait {
                    do {
                        try PersistenceController.shared.container.viewContext.save()
                        self.comparisonsDataModel.resume()
                    } catch {
                        print("Error merging changes with main context: \(error)")
                    }
                }
            } catch {
                print("Error saving private context: \(error)")
            }
        }
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
