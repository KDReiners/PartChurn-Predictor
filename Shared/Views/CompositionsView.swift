//
//  CompositionsView.swift
//  PartChurn Predictor
//
//  Created by Klaus-Dieter Reiners on 17.08.22.
//

import SwiftUI

struct CompositionsView: View {
    @ObservedObject var compositionDataModel: CompositionsModel
    @ObservedObject var predictionsDataModel = PredictionsModel()
    @ObservedObject var valuesTableProvider = ValuesTableProvider()
    @ObservedObject var mlDataTableProvider: MlDataTableProvider
    @State var mlSelection: String? = nil
    @State var clusterSelection: PredictionsModel.PredictionCluster?
    @State var selectedColumnCombination: [Columns]?
    @State var selectedTimeSeriesCombination: [String]?
    @State var selectedLookAhead: Int? = 0
    @State var maxLookAhead = 0
    
    var highestFrom: Int?
    var valuesView: ValuesView?
    var unionResult: UnionResult!
    var model: Models
    var composer: FileWeaver?
    var combinator: Combinator!
    var availableAlgorithms = AlgorithmsModel().items.sorted(by: { $0.algorithm2algorithmtype!.name! < $1.algorithm2algorithmtype!.name! })
    var mlAlgorithms: [String]!
    
    init(model: Models, composer: FileWeaver, combinator: Combinator) {
        self.model = model
        self.compositionDataModel = CompositionsModel(model: self.model)
        self.composer = composer
        self.combinator = combinator
        mlAlgorithms = availableAlgorithms.map( { $0.name! })
        self.mlDataTableProvider = MlDataTableProvider(model: self.model)
        self.mlDataTableProvider.mlDataTable = composer.mlDataTable_Base!
        self.mlDataTableProvider.orderedColumns = composer.orderedColumns!
        unionResult = try? self.mlDataTableProvider.buildMlDataTable()
        self.mlDataTableProvider.updateTableProvider()
        valuesView = ValuesView(mlDataTableProvider: self.mlDataTableProvider)
        compositionDataModel.retrievePredictionClusters()
        predictionsDataModel.createPredictionForModel(model: self.model)
        predictionsDataModel.getTimeSeries()
    }
    var body: some View {
        VStack {
            HStack(alignment: .center)
            {
                VStack(alignment: .leading)
                {
                    HStack(alignment: .center) {
                        Text("Data Cluster")
                            .font(.title)
                        Spacer()
                        if predictionsDataModel.arrayOfPredictions.count > 0 {
                            Button("Delete") {
                                predictionsDataModel.deleteAllRecords(predicate: nil)
                                clusterSelection = nil
                                predictionsDataModel.arrayOfPredictions = [PredictionsModel.PredictionCluster]()
                            }
                        }
                        else if compositionDataModel.arrayOfClusters.count > 0 {
                            Button("Save") {
                                savePredictions()
                                predictionsDataModel.createPredictionForModel(model: self.model)
                            }
                        }
                    }
                    if predictionsDataModel.arrayOfPredictions.count > 0 {
                        List(predictionsDataModel.arrayOfPredictions.sorted(by: {
                            $0.seriesDepth < $1.seriesDepth }), id: \.self, selection: $clusterSelection) { prediction in
                                HStack(alignment: .center) {
                                    Text(prediction.groupingPattern!)
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    clusterSelection = clusterSelection == prediction ? nil: prediction
                                }
                                
                            }
                    }
                    else if compositionDataModel.arrayOfClusters.count > 0 {
                        List(compositionDataModel.arrayOfClusters.sorted(by: { $0.seriesDepth < $1.seriesDepth }), id:\.self) { cluster in
                            Text(cluster.groupingPattern!)
                        }
                    }
                }
                .frame(minWidth: 280)
                .padding()
                
                VStack(alignment: .leading) {
                    if predictionsDataModel.arrayOfPredictions.count > 0 && clusterSelection != nil {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading) {
                                Text("Timeseries")
                                    .font(.title)
                                List((clusterSelection?.timeSeries.sorted(by: { $0.from < $1.from }))!, id: \.self) { series in
                                    Text(String(series.from) + " - " + String(series.to))
                                }
                            }
                            VStack(alignment: .leading) {
                                Text("Look Ahead")
                                    .font(.title)
                                PredictionsModel.PredictionCluster.LookAheadView(selectedLookAhead: $selectedLookAhead, maxLookAhead: $maxLookAhead)
                            }
                        }
                        Text("Columns")
                            .font(.title)
                            .padding(.top, 15)
                        List((clusterSelection?.columns.sorted(by: { $0.orderno < $1.orderno }))!, id:\.self ) { column in
                            Text(column.name!)
                        }
                    }
                }
                .onChange(of: selectedLookAhead) { newLookAhead in
                    print("selected lookahead didchange")
                }
                .onChange(of: clusterSelection) { newClusterSelection in
                    maxLookAhead = clusterSelection?.maxLookAhead ?? 0
                    self.mlDataTableProvider.selectedColumns = newClusterSelection?.columns
                    if let timeSeriesRows = newClusterSelection?.connectedTimeSeries {
                        var selectedTimeSeries = [[Int]]()
                        for row in timeSeriesRows {
                            let innerResult = row.components(separatedBy: ", ").map { Int($0)! }
                            selectedTimeSeries.append(innerResult)
                        }
                        self.mlDataTableProvider.timeSeries = selectedTimeSeries
                        
                        
                    } else {
                        self.mlDataTableProvider.timeSeries = nil
                    }
                    self.mlDataTableProvider.mlDataTable = composer?.mlDataTable_Base
                    self.mlDataTableProvider.orderedColumns = composer?.orderedColumns!
                    self.mlDataTableProvider.selectedColumns = newClusterSelection?.columns
                    self.mlDataTableProvider.prediction = newClusterSelection?.prediction
                    generateValuesView()

                }
                .frame(minWidth: 160)
                .padding()
                VStack(alignment: .leading) {
                    HStack(alignment: .center) {
                        Text("Algorithmus")
                            .font(.title)
                        Spacer()
                        Button("Train..") {
                            train(regressorName: mlSelection)
                        }
                        .disabled(mlSelection == nil || clusterSelection == nil)
                    }.frame(minWidth: 230)
                    HStack {
                        List(mlAlgorithms, id: \.self, selection: $mlSelection) { algorithm in
                            HStack {
                                Text(algorithm)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                mlSelection = mlSelection == algorithm ? nil: algorithm
                            }
                        }
                        .frame(minWidth: 250)
                        .onChange(of: mlSelection) { newSelection in
                            self.mlDataTableProvider.regressorName = newSelection
                            generatePredictionView()
                            
                        }
                    }
                    HStack {
                        Text("Resultset Statistics")
                            .font(.title)
                            .padding(.top, 15)
                        Spacer()
                        Button("Delete All") {
                            PredictionsModel().deleteAllRecords(predicate: nil)
                            PredictionMetricsModel().deleteAllRecords(predicate: nil)
                            PredictionMetricValueModel().deleteAllRecords(predicate: nil)
                        }
                    }
                    
                    List {
                        VStack {
                            Group {
                                Text("Table").font(.title3)
                                HStack {
                                    Text("All rows count")
                                    Spacer()
                                    let countNumber = NSNumber(value: mlDataTableProvider.tableStatistics?.absolutRowCount ?? 0)
                                    Text(BaseServices.intFormatter.string(from: countNumber)!)
                                }
                                HStack {
                                    Text("Filtered rows count")
                                    Spacer()
                                    let countNumber = NSNumber(value: mlDataTableProvider.tableStatistics?.filteredRowCount ?? 0)
                                    Text(BaseServices.intFormatter.string(from: countNumber)!)
                                }
                            }
                            if (mlDataTableProvider.tableStatistics?.targetStatistics.count ?? 0) > 0 {
                                Divider()
                                VStack {
                                    Group {
                                        Text("General").font(.title3)
                                        HStack {
                                            Text("TargetValue")
                                            Spacer()
                                            let targetNumber = NSNumber(value: mlDataTableProvider.tableStatistics!.targetStatistics[0].targetValue)
                                            Text(BaseServices.intFormatter.string(from: targetNumber)!)
                                        }
                                        HStack {
                                            Text("TargetPopulation")
                                            Spacer()
                                            let targetPopulationNumber = NSNumber(value: mlDataTableProvider.tableStatistics!.targetStatistics[0].targetPopulation)
                                            Text(BaseServices.intFormatter.string(from: targetPopulationNumber)!)
                                        }
                                    }
                                    Divider()
                                    Group {
                                        Text("Optimum").font(.title3)
                                        HStack {
                                            Text("Targets: ")
                                            Spacer()
                                            let targetsAtOptimumNumber = NSNumber(value: mlDataTableProvider.tableStatistics!.targetStatistics[0].targetsAtOptimum)
                                            Text(BaseServices.intFormatter.string(from: targetsAtOptimumNumber)!)
                                        }
                                        HStack {
                                            Text("Dirties: ")
                                            Spacer()
                                            let dirtiesAtOptimumNumber = NSNumber(value: mlDataTableProvider.tableStatistics!.targetStatistics[0].dirtiesAtOptimum)
                                            Text(BaseServices.intFormatter.string(from: dirtiesAtOptimumNumber)!)
                                        }
                                        HStack {
                                            Text("PredictionValue: ")
                                            Spacer()
                                            let predictionValueAtOptimumNumber = NSNumber(value: mlDataTableProvider.tableStatistics!.targetStatistics[0].predictionValueAtOptimum)
                                            Text(BaseServices.doubleFormatter.string(from: predictionValueAtOptimumNumber)!)
                                        }
                                    }
                                    Divider()
                                    Group {
                                        Text("Threshold").font(.title3)
                                        HStack {
                                            Text("Max Dirties:")
                                            Spacer()
                                            let thresholdNumber = NSNumber(value: mlDataTableProvider.tableStatistics!.targetStatistics[0].threshold)
                                            Text(BaseServices.intFormatter.string(from: thresholdNumber)!)
                                        }
                                        HStack {
                                            Text("Targets: ")
                                            Spacer()
                                            let targetsAtThresholdNumber = NSNumber(value: mlDataTableProvider.tableStatistics!.targetStatistics[0].targetsAtThreshold)
                                            Text(BaseServices.intFormatter.string(from: targetsAtThresholdNumber)!)
                                        }
                                        HStack {
                                            Text("Dirties: ")
                                            Spacer()
                                            let dirtiesAtThresholdNumber = NSNumber(value: mlDataTableProvider.tableStatistics!.targetStatistics[0].dirtiesAtThreshold)
                                            Text(BaseServices.intFormatter.string(from: dirtiesAtThresholdNumber)!)
                                        }
                                        HStack {
                                            Text("PredictionValue: ")
                                            Spacer()
                                            let predictionValueAtThresholdNumber = NSNumber(value: mlDataTableProvider.tableStatistics!.targetStatistics[0].predictionValueAtThreshold)
                                            Text(BaseServices.doubleFormatter.string(from: predictionValueAtThresholdNumber)!)
                                        }
                                    }
                                    
                                }
                            }
                        }
                    }.frame(minWidth: 250)
                }
                .padding()
                VStack(alignment: .leading) {
                    HStack(alignment: .center) {
                    Text("Algorithmus KPI")
                        .font(.title)
                    Spacer()
                        Button("Delete all...") {
                            let metricValuesDataModel = MetricvaluesModel()
                
                            metricValuesDataModel.deleteAllRecords(predicate: nil)
                        }
                    }
                    AlgorithmsModel.valueList(prediction: (clusterSelection?.prediction), algorithmName: mlSelection ?? "unbekannt")
                    
                }
                .frame(minWidth: 250)
                .padding()
            }
            Divider()
            VStack(alignment: .leading) {
                valuesView
            }.padding()
        }
    }
    func generateValuesView() {
        self.mlDataTableProvider.mlDataTableRaw = nil
        mlSelection = clusterSelection?.prediction == nil ? nil: mlSelection
        self.mlDataTableProvider.mlDataTable = try? self.mlDataTableProvider.buildMlDataTable().mlDataTable
        self.mlDataTableProvider.updateTableProvider()
        self.mlDataTableProvider.loaded = false
    }
    func savePredictions() {
        predictionsDataModel.savePredictions(model: self.model)
    }
    fileprivate func generatePredictionView() {
        self.mlDataTableProvider.filterViewProvider = nil
        self.mlDataTableProvider.updateTableProvider()
        self.mlDataTableProvider.loaded = false
    }
    
    private func train(regressorName: String?) {
        var trainer = Trainer(mlDataTableProvider: self.mlDataTableProvider, model: self.model)
        trainer.model = self.model
        trainer.createModel(algorithmName: $mlSelection.wrappedValue!)
        DispatchQueue.global().sync {
            generatePredictionView()
        }
    }
}
