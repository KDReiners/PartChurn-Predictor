//
//  ModelsView.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 17.08.23.
//
import Foundation
import SwiftUI
import CoreData
import UniformTypeIdentifiers



struct ModelsView: View {
    var modelDataModel = ModelsModel()
    var timeslicesDataModel = TimeSlicesModel()
    var model: Models
    var observation: Observations!
    var timeSlices: [Timeslices] = []
    var labelWidth = 100
    @ObservedObject var comparisonsDataModel: ComparisonsModel
    @State var churnPublisher: ChurnPublisher!
    @State private var selectedPeriod: TimeLord.PeriodTypes?
    @State private var selectedPeriodIndex: Int
    @State private var selectedTimeSlice: Timeslices?
    @State private var observationTimeSliceFrom: Timeslices?
    @State private var observationTimeSliceTo: Timeslices?
    @State private var selectedTimeSliceIndex: Int
    @State private var observationIndexFrom: Int
    @State private var observationIndexTo: Int
    
    let periodLabels = ["Year", "Half Year", "Quarter", "Month"]
    
    
    init(model: Models) {
        self.model = model
        timeSlices = timeslicesDataModel.items.filter( { $0.timeslice2models == model} )
        timeSlices.sort(by: { $0.value < $1.value })
        self.comparisonsDataModel  = ComparisonsModel(model: self.model)
        self.selectedPeriodIndex = Int(model.periodtype)
        //                comparisonDataModel.deleteAllRecords(predicate: nil)
        if !timeSlices.isEmpty {
            observation = (model.model2observations?.allObjects as? [Observations])?.first
            //            if observation == nil {
            //                observation = ObservationsModel().insertRecord()
            //                observation?.observation2model = model
            //
            //            }
            if model.model2lastlearningtimeslice == nil {
                model.model2lastlearningtimeslice = timeSlices.first
            }
            if model.model2observationtimeslicefrom == nil {
                model.model2observationtimeslicefrom = timeSlices.first
            }
            if model.model2observationtimesliceto == nil {
                model.model2observationtimesliceto = timeSlices.first
            }
            guard let selectedTimeSlice = model.model2lastlearningtimeslice else {
                fatalError("Error in grepping timeslice")
            }
            guard let observationTimeSliceFrom = model.model2observationtimeslicefrom else {
                fatalError("Error in grepping timeslice")
            }
            guard let observationTimeSliceTo = model.model2observationtimesliceto else {
                fatalError("Error in grepping timeslice")
            }
            self.churnPublisher = ChurnPublisher(model: self.model)
            self.selectedTimeSlice = selectedTimeSlice
            let index = timeSlices.firstIndex(of: selectedTimeSlice)
            self.selectedTimeSliceIndex = index!
            let observationFromIndex = timeSlices.firstIndex(of: observationTimeSliceFrom)
            self.observationIndexFrom = observationFromIndex!
            let observationToIndex = timeSlices.firstIndex(of: observationTimeSliceTo)
            self.observationIndexTo = observationToIndex!
            self.churnPublisher.timeSliceFrom = observationTimeSliceFrom
            self.churnPublisher.timeSliceTo = observationTimeSliceTo
        } else {
            selectedTimeSliceIndex = 0
            self.observationIndexFrom = 0
            self.observationIndexTo = 0
            
        }
    }
    var body: some View {
        VStack(alignment: .leading){
            HStack {
                GroupBox(label: Text("Model").font(.title)) {
                    Picker("Type of Period:", selection: $selectedPeriodIndex) {
                        ForEach(0..<periodLabels.count, id: \.self) { index in
                            Text(periodLabels[index])
                        }
                    }
                    .onChange(of: selectedPeriodIndex) { newValue in
                        self.model.periodtype = Int16(newValue)
                        BaseServices.save()
                    }
                    Picker("Learn until:", selection: $selectedTimeSliceIndex) {
                        ForEach(timeSlices.indices, id: \.self) { index in
                            Text("\(timeSlices[index].value)")
                        }
                    }
                    .onChange(of: selectedTimeSliceIndex) { newValue in
                        self.selectedTimeSlice = timeSlices[newValue]
                        self.model.model2lastlearningtimeslice = selectedTimeSlice
                        BaseServices.save()
                    }
                }
                
                GroupBox(label: Text("Learning").font(.title)) {
                    Picker("Observation from:", selection: $observationIndexFrom) {
                        ForEach(timeSlices.indices, id: \.self) { index in
                            Text("\(timeSlices[index].value)")
                        }
                    }
                    .onChange(of: observationIndexFrom) { newValue in
                        self.observationTimeSliceFrom = timeSlices[newValue]
                        self.model.model2observationtimeslicefrom = self.observationTimeSliceFrom
                        self.churnPublisher.timeSliceFrom = self.observationTimeSliceFrom
                        BaseServices.save()
                    }
                    Picker("Observation to:", selection: $observationIndexTo) {
                        ForEach(timeSlices.indices, id: \.self) { index in
                            Text("\(timeSlices[index].value)")
                        }
                    }
                    .onChange(of: observationIndexTo) { newValue in
                        self.observationTimeSliceTo = timeSlices[newValue]
                        self.model.model2observationtimesliceto = self.observationTimeSliceTo
                        self.churnPublisher.timeSliceTo = self.observationTimeSliceTo
                        BaseServices.save()
                    }
                }
            }
            HStack {
                Button("Get Best of") {
                    let publisher =  ChurnPublisher(model: self.model)
                    publisher.cleanUp(comparisonsDataModel: comparisonsDataModel)
                    Task {
                        await publisher.calculate(comparisonsDataModel: comparisonsDataModel )
                    }
                }
                Button("delete Comparisons") {
                    ComparisonsModel(model: self.model).deleteAllRecords(predicate: nil)
                }
            }
        }.padding()
        Spacer()
        ReportingView(model: self.model, comparisonsDataModel: self.comparisonsDataModel)
            .frame(alignment: .topLeading)
            .padding()
        //        .background(Color.white)
    }
}
struct ReportingView: View {
    @ObservedObject var comparisonsDataModel: ComparisonsModel
    @State private var id: UUID?
    @State private var selectedSummaryItem: ComparisonsModel.ComparisonSummaryEntry?
    var model: Models
    var modelColumnsMap: Dictionary<String, String> = [:]
    var columnsDataModel: ColumnsModel
    @State private var sorting = [KeyPathComparator(\ComparisonsModel.ComparisonSummaryEntry.lblTargetReported)]
    init(model: Models, comparisonsDataModel: ComparisonsModel ) {
        self.model = model
        self.comparisonsDataModel = comparisonsDataModel
        columnsDataModel = ColumnsModel(model: self.model)
        modelColumnsMap["primaryKeyValue"] = columnsDataModel.primaryKeyColumn!.name!
        modelColumnsMap["timeBase"] = columnsDataModel.timeStampColumn!.name!
        modelColumnsMap["targetReported"] = columnsDataModel.targetColumns.first!.name!
        modelColumnsMap["targetPredicted"] = "PREDICTED: " + columnsDataModel.targetColumns.first!.name!
    }
    var body: some View {
        let summaryItems = comparisonsDataModel.reportingSummaries.sorted(by: { $0.primaryKeyValue < $1.primaryKeyValue})
        let votings = comparisonsDataModel.votings
        let voters = comparisonsDataModel.voters
        let history = comparisonsDataModel.churnStatistics
        let votersCount = summaryItems.reduce(0) { (result, summaryItem) in
            return result + summaryItem.votersCount
            
        }
        VStack {
            HStack {
                HStack {
                    Text("Rows count")
                    Text("\(summaryItems.count)")
                    Text("Voters count")
                    Text(voters ?? "")
                }
                Spacer()
                
            }.background(Color.green)
            Table(history) {
                TableColumn("TIMEBASE", value: \.lblTimebase)
                TableColumn("TARGETSCOUNT", value: \.lblTargetCount)
                TableColumn("NONTARGETSCOUNT", value: \.lblNonTargetCount)
            }
            Table(summaryItems, selection: $id) {
                TableColumn("DATE", value: \.reportingDateStringValue)
                TableColumn(modelColumnsMap["primaryKeyValue"]!, value: \.primaryKeyValue)
                TableColumn("VOTERSCOUNT", value: \.lblVotersCount)
                TableColumn(modelColumnsMap[ "targetReported"]!, value: \.lblTargetReported)
                TableColumn(modelColumnsMap[ "targetPredicted"]!, value: \.lblTargetPredicted)
            }
            .onChange(of: id) { newValue in
                selectedSummaryItem = summaryItems.first(where: { $0.id == newValue})
            }
            Button("TRANSFER TO SQLSERVER") {
                transferToSQLSERVER()
            }.frame(alignment: .trailing)
            if votings.count > 0 {
                Table(votings) {
                    Group {
                        TableColumn("PrimaryKey", value: \ComparisonsModel.Voting.primaryKey)
                        TableColumn("ALGORITHM", value: \ComparisonsModel.Voting.algorithm)
                        TableColumn("ENTRIES", value: \.entriesCount)
                        TableColumn("FOUND TARGETS", value: \.foundTargets)
                        TableColumn("PROPOSED TARGETS", value: \.proposedTargets)
                        TableColumn("OWNVOTINGS", value: \.uniqueContributions)
                        TableColumn("COMMONVOTINGS", value: \.mixedContributions)
                        TableColumn("LOOKAHEAD", value: \.lookAhead)
                        TableColumn("TIMESLICES", value: \.timeSlices)
                        TableColumn("PRECISION", value: \.precision)
                        
                    }
                    Group {
                        TableColumn("RECALL", value: \ComparisonsModel.Voting.recall)
                        TableColumn("F1-SCORE", value: \.f1Score)
                    }
                }
            }
            if selectedSummaryItem?.comparisonsDetails != nil {
                Table(selectedSummaryItem!.comparisonsDetails) {
                    TableColumn("ID", value: \.observationId)
                    TableColumn(modelColumnsMap["timeBase"]!, value: \.timebase)
                    TableColumn("TimeSlices", value:\.timeslices)
                    TableColumn("LookAhead", value: \.lookahead)
                    TableColumn("Algorithm", value: \.algorithm)
                    TableColumn(modelColumnsMap[ "targetReported"]!, value: \.targetreported)
                    TableColumn(modelColumnsMap[ "targetPredicted"]!, value: \.targetpredicted)
                }
            }
            Button("Export to Excel") {
                
            }
        }
        .onAppear {
            comparisonsDataModel.retrieveHistory()
            comparisonsDataModel.gather()
        }
        
    }
    func transferToSQLSERVER() {
        let summaryItems = comparisonsDataModel.reportingSummaries.sorted(by: { $0.primaryKeyValue < $1.primaryKeyValue})
        let sqlHelper = SQLHelper()
        let sqlDate = BaseServices.standardDateFormatterWithoutTime.string(from: Date.now)
        let deleteCommand = """
                            DELETE FROM  [sao].[CHURN_PREDICTIONS2SF] WHERE REPORTDATE = '\(sqlDate)'
                            """
        sqlHelper.runSQLCommand(model: self.model, sqlCommand: deleteCommand)
        let summaryScope =  summaryItems.filter( { $0.targetsReported == 1 }).sorted(by: { $0.primaryKeyValue < $1.primaryKeyValue})
        var i = 1
        for summaryItem in summaryScope {
            print("bearbeite Zeile: \(i)")
            let custno = summaryItem.primaryKeyValue
            let voters = summaryItem.votersCount
            let salesForceExport = SalesForceExport(reportDate: sqlDate, s_custno: custno, voters: voters)
            sqlHelper.runSQLCommand(model: self.model, sqlCommand: salesForceExport.sqlCommand)
            i += 1
        }
    }
    struct SalesForceExport {
        var reportDate: String
        var s_custno: String
        var voters: Int
        var sqlCommand: String {
            get {
                return """
                    INSERT INTO [sao].[CHURN_PREDICTIONS2SF] ([REPORTDATE], [S_CUSTNO], VOTERSCOUNT)
                    VALUES ('\(reportDate)', '\(s_custno)',\(voters) );
                """
            }
        }
    }
    
}
struct ModelsView_Previews: PreviewProvider {
    static var previews: some View {
        ModelsView(model: ModelsModel().items.first!)
    }
}


