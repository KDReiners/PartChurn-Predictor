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
    @State var mlSelection: String? = nil
    @State var clusterSelection: PredictionsModel.predictionCluster?
    @State var selectedColumnCombination: [Columns]?
    @State var selectedTimeSeriesCombination: [String]?
    @ObservedObject var mlDataTableProvider: MlDataTableProvider
    var valuesView: ValuesView?
    var unionResult: UnionResult!
    var model: Models
    var composer: FileWeaver?
    var combinator: Combinator!
    var mlAlgorithms = ["MLLinearRegressor", "MLDecisionTreeRegressor", "MLRandomForestRegressor", "MLBoostedTreeRegressor"]
    
    init(model: Models, composer: FileWeaver, combinator: Combinator) {
        self.model = model
        self.compositionDataModel = CompositionsModel(model: self.model)
        self.composer = composer
        self.combinator = combinator
        self.mlDataTableProvider = MlDataTableProvider()
        self.mlDataTableProvider.mlDataTable = composer.mlDataTable_Base!
        self.mlDataTableProvider.orderedColumns = composer.orderedColumns!
        self.mlDataTableProvider.model = self.model
        unionResult = self.mlDataTableProvider.buildMlDataTable()
        self.mlDataTableProvider.updateTableProvider()
        valuesView = ValuesView(mlDataTableProvider: self.mlDataTableProvider)
        compositionDataModel.presentCalculationTasks()
        predictionsDataModel.predictions(model: self.model)
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
                                predictionsDataModel.predictions(model: self.model)
                            }
                        }
                        else if compositionDataModel.arrayOfClusters.count > 0 {
                            Button("Save") {
                                savePredictions()
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
                .frame(width: 270)
                .padding()
                
                VStack(alignment: .leading) {
                    if predictionsDataModel.arrayOfPredictions.count > 0 && clusterSelection != nil {
                        Text("Timeseries")
                            .font(.title)
                        List((clusterSelection?.timeSeries.sorted(by: { $0.from < $1.from }))!, id: \.self) { series in
                            Text(String(series.from) + " - " + String(series.to))
                        }
                        Text("Columns")
                            .font(.title)
                            .padding(.top, 15)
                        List((clusterSelection?.columns.sorted(by: { $0.orderno < $1.orderno }))!, id:\.self ) { column in
                            Text(column.name!)
                        }
                    }
                }
                .onChange(of: clusterSelection) { newClusterSelection in
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
                    }.frame(width: 250)
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
                        .frame(width: 250)
                        .onChange(of: mlSelection) { newSelection in
                            self.mlDataTableProvider.regressorName = newSelection
                            generatePredictionView()
                            
                        }
                    }
                    Text("Resultset Statistics")
                        .font(.title)
                        .padding(.top, 15)
                    List {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("All rows count")
                                Spacer()
                                let countNumber = NSNumber(value: mlDataTableProvider.tableStatistics!.absolutRowCount)
                                Text(BaseServices.intFormatter.string(from: countNumber)!)
                            }
                            HStack {
                                Text("Filtered rows count")
                                Spacer()
                                let countNumber = NSNumber(value: mlDataTableProvider.tableStatistics!.filteredRowCount)
                                Text(BaseServices.intFormatter.string(from: countNumber)!)
                            }
                                
                        }
                    }.frame(width: 250)
                }
                .padding()
                VStack(alignment: .leading) {
                    HStack(alignment: .center) {
                    Text("Algorithmus KPI")
                        .font(.title)
                    Spacer()
                        Button("Delete all...") {
                            let metricValuesDataModel = MetricvaluesModel()
                            let predicate = NSPredicate(format: "metricvalue2model == %@", self.model)
                            metricValuesDataModel.deleteAllRecords(predicate: predicate)
                        }
                    }
                    AlgorithmsModel.valueList(prediction: (clusterSelection?.prediction), algorithmName: mlSelection ?? "unbekannt")
                    
                }
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
        self.mlDataTableProvider.mlDataTable = self.mlDataTableProvider.buildMlDataTable().mlDataTable
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
        var trainer = Trainer(mlDataTableFactory: self.mlDataTableProvider)
        trainer.createModel(regressorName: $mlSelection.wrappedValue!)
        generatePredictionView()
    }
}
