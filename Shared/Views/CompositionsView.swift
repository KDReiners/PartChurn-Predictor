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
    @ObservedObject var dataContext: DataContext
    @State var mlSelection: String? = nil
    @State var clusterSelection: PredictionsModel.PredictionCluster?
    @State var selectedColumnCombination: [Columns]?
    @State var selectedTimeSeriesCombination: [String]?
    @State var selectedLookAhead: Int? = 0
    @State var maxLookAhead = 0
    @State var unionResult: UnionResult!
    @State var valuesView: ValuesView? = nil
    
    var highestFrom: Int?
    var model: Models
    var availableAlgorithms = AlgorithmsModel().items.sorted(by: { $0.algorithm2algorithmtype!.name! < $1.algorithm2algorithmtype!.name! })
    var mlAlgorithms: [String]!
    
    init(mlDataTableProviderContext: SimulationController.MlDataTableProviderContext) {
        self.dataContext = DataContext(mlDataTableProviderContext: mlDataTableProviderContext)
        self.model = mlDataTableProviderContext.model!
        self.compositionDataModel = CompositionsModel(model: self.model)
        self.mlAlgorithms = availableAlgorithms.map( { $0.name! })
        self.dataContext.mlDataTableProviderContext.mlDataTableProvider.delegate = self.dataContext
        valuesView = ValuesView(mlDataTableProvider: dataContext.mlDataTableProviderContext.mlDataTableProvider)
        self.unionResult = try? dataContext.mlDataTableProviderContext.mlDataTableProvider.buildMlDataTable(lookAhead: 0)
        compositionDataModel.retrievePredictionClusters()
        predictionsDataModel.createPredictionForModel(model: self.model)
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
                    dataContext.mlDataTableProviderContext = SimulationController.returnFittingProviderContext(model: self.model, lookAhead: newLookAhead ?? 0, prediction: clusterSelection?.prediction)!
                    self.dataContext.mlDataTableProviderContext.mlDataTableProvider.delegate = self.dataContext
                    self.dataContext.mlDataTableProviderContext.mlDataTableProvider.selectedColumns = clusterSelection?.columns
                    generateValuesView()
                }
                .onChange(of: clusterSelection) { newClusterSelection in
                    maxLookAhead = clusterSelection?.maxLookAhead ?? 0
                    dataContext.mlDataTableProviderContext.mlDataTableProvider.selectedColumns = newClusterSelection?.columns
                    dataContext.mlDataTableProviderContext.clusterSelection = newClusterSelection
                    if let timeSeriesRows = newClusterSelection?.connectedTimeSeries {
                        var selectedTimeSeries = [[Int]]()
                        for row in timeSeriesRows {
                            let innerResult = row.components(separatedBy: ", ").map { Int($0)! }
                            selectedTimeSeries.append(innerResult)
                        }
                        self.dataContext.mlDataTableProviderContext.mlDataTableProvider.timeSeries = selectedTimeSeries
                        
                        
                    } else {
                        self.dataContext.mlDataTableProviderContext.mlDataTableProvider.timeSeries = nil
                    }
                    self.dataContext.mlDataTableProviderContext.mlDataTableProvider.mlDataTable = self.dataContext.mlDataTableProviderContext.composer?.mlDataTable_Base
                    self.dataContext.mlDataTableProviderContext.mlDataTableProvider.orderedColumns = self.dataContext.mlDataTableProviderContext.composer?.orderedColumns!
                    self.dataContext.mlDataTableProviderContext.mlDataTableProvider.selectedColumns = newClusterSelection?.columns
                    self.dataContext.mlDataTableProviderContext.mlDataTableProvider.prediction = newClusterSelection?.prediction
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
                            train(regressorName: mlSelection, mlDataTableProviderContext: dataContext.mlDataTableProviderContext)
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
                            self.dataContext.mlDataTableProviderContext.mlDataTableProvider.regressorName = newSelection
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
                                    let countNumber = NSNumber(value: dataContext.mlDataTableProviderContext.mlDataTableProvider.tableStatistics?.absolutRowCount ?? 0)
                                    Text(BaseServices.intFormatter.string(from: countNumber)!)
                                }
                                HStack {
                                    Text("Filtered rows count")
                                    Spacer()
                                    let countNumber = NSNumber(value: dataContext.mlDataTableProviderContext.mlDataTableProvider.tableStatistics?.filteredRowCount ?? 0)
                                    Text(BaseServices.intFormatter.string(from: countNumber)!)
                                }
                            }
                            if (dataContext.mlDataTableProviderContext.mlDataTableProvider.tableStatistics?.targetStatistics.count ?? 0) > 0 {
                                Divider()
                                VStack {
                                    Group {
                                        Text("General").font(.title3)
                                        HStack {
                                            Text("TargetValue")
                                            Spacer()
                                            let targetNumber = NSNumber(value: dataContext.mlDataTableProviderContext.mlDataTableProvider.tableStatistics!.targetStatistics[0].targetValue)
                                            Text(BaseServices.intFormatter.string(from: targetNumber)!)
                                        }
                                        HStack {
                                            Text("TargetPopulation")
                                            Spacer()
                                            let targetPopulationNumber = NSNumber(value: dataContext.mlDataTableProviderContext.mlDataTableProvider.tableStatistics!.targetStatistics[0].targetPopulation)
                                            Text(BaseServices.intFormatter.string(from: targetPopulationNumber)!)
                                        }
                                    }
                                    Divider()
                                    Group {
                                        Text("Optimum").font(.title3)
                                        HStack {
                                            Text("Targets: ")
                                            Spacer()
                                            let targetsAtOptimumNumber = NSNumber(value: dataContext.mlDataTableProviderContext.mlDataTableProvider.tableStatistics!.targetStatistics[0].targetsAtOptimum)
                                            Text(BaseServices.intFormatter.string(from: targetsAtOptimumNumber)!)
                                        }
                                        HStack {
                                            Text("Dirties: ")
                                            Spacer()
                                            let dirtiesAtOptimumNumber = NSNumber(value: dataContext.mlDataTableProviderContext.mlDataTableProvider.tableStatistics!.targetStatistics[0].dirtiesAtOptimum)
                                            Text(BaseServices.intFormatter.string(from: dirtiesAtOptimumNumber)!)
                                        }
                                        HStack {
                                            Text("PredictionValue: ")
                                            Spacer()
                                            let predictionValueAtOptimumNumber = NSNumber(value: dataContext.mlDataTableProviderContext.mlDataTableProvider.tableStatistics!.targetStatistics[0].predictionValueAtOptimum)
                                            Text(BaseServices.doubleFormatter.string(from: predictionValueAtOptimumNumber)!)
                                        }
                                    }
                                    Divider()
                                    Group {
                                        Text("Threshold").font(.title3)
                                        HStack {
                                            Text("Max Dirties:")
                                            Spacer()
                                            let thresholdNumber = NSNumber(value: dataContext.mlDataTableProviderContext.mlDataTableProvider.tableStatistics!.targetStatistics[0].threshold)
                                            Text(BaseServices.intFormatter.string(from: thresholdNumber)!)
                                        }
                                        HStack {
                                            Text("Targets: ")
                                            Spacer()
                                            let targetsAtThresholdNumber = NSNumber(value: dataContext.mlDataTableProviderContext.mlDataTableProvider.tableStatistics!.targetStatistics[0].targetsAtThreshold)
                                            Text(BaseServices.intFormatter.string(from: targetsAtThresholdNumber)!)
                                        }
                                        HStack {
                                            Text("Dirties: ")
                                            Spacer()
                                            let dirtiesAtThresholdNumber = NSNumber(value: dataContext.mlDataTableProviderContext.mlDataTableProvider.tableStatistics!.targetStatistics[0].dirtiesAtThreshold)
                                            Text(BaseServices.intFormatter.string(from: dirtiesAtThresholdNumber)!)
                                        }
                                        HStack {
                                            Text("PredictionValue: ")
                                            Spacer()
                                            let predictionValueAtThresholdNumber = NSNumber(value: dataContext.mlDataTableProviderContext.mlDataTableProvider.tableStatistics!.targetStatistics[0].predictionValueAtThreshold)
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
                self.valuesView
            }.padding()
        }.onAppear {
            generateValuesView()
        }
    }
    private func train(regressorName: String?, mlDataTableProviderContext: SimulationController.MlDataTableProviderContext) {
        self.dataContext.mlDataTableProviderContext = mlDataTableProviderContext
        var trainer = Trainer(mlDataProviderContext: self.dataContext.mlDataTableProviderContext)
        trainer.model = self.model
        trainer.createModel(algorithmName: $mlSelection.wrappedValue!)
        DispatchQueue.global().sync {
            generatePredictionView()
        }
    }
    func generateValuesView() {
        let callingFunction = #function
        let className = String(describing: type(of: self))
        self.dataContext.mlDataTableProviderContext.mlDataTableProvider.mlDataTableRaw = nil
        if clusterSelection?.connectedTimeSeries != nil {
            self.dataContext.mlDataTableProviderContext.mlDataTableProvider.timeSeries = clusterSelection?.selectedTimeSeries
        } else {
            self.dataContext.mlDataTableProviderContext.mlDataTableProvider.timeSeries = nil
        }
        mlSelection = clusterSelection?.prediction == nil ? nil: mlSelection
        self.dataContext.mlDataTableProviderContext.mlDataTableProvider.regressorName = mlSelection
        self.dataContext.mlDataTableProviderContext.mlDataTableProvider.mlDataTable = try? self.dataContext.mlDataTableProviderContext.mlDataTableProvider.buildMlDataTable(lookAhead: selectedLookAhead ?? 0).mlDataTable
        self.dataContext.mlDataTableProviderContext.mlDataTableProvider.updateTableProvider(callingFunction: callingFunction, className: className, lookAhead: selectedLookAhead ?? 0)
        self.dataContext.mlDataTableProviderContext.mlDataTableProvider.loaded = false
        self.valuesView = ValuesView(mlDataTableProvider: dataContext.mlDataTableProviderContext.mlDataTableProvider)
        
    }
    func savePredictions() {
        predictionsDataModel.savePredictions(model: self.model)
    }
    fileprivate func generatePredictionView() {
        let callingFunction = #function
        let className = String(describing: type(of: self))
        self.dataContext.mlDataTableProviderContext.mlDataTableProvider.filterViewProvider = nil
        self.dataContext.mlDataTableProviderContext.mlDataTableProvider.updateTableProvider(callingFunction: callingFunction, className: className, lookAhead: selectedLookAhead ?? 0)
        self.dataContext.mlDataTableProviderContext.mlDataTableProvider.loaded = false
    }
}


