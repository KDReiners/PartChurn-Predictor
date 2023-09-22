//
//  ModelsView.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 17.08.23.
//
import Foundation
import SwiftUI
import CoreData


struct ModelsView: View {
    var modelDataModel = ModelsModel()
    var timeslicesDataModel = TimeSlicesModel()
    var model: Models
    var observation: Observations!
    var timeSlices: [Timeslices] = []
    
    @ObservedObject var comparisonsDataModel: ComparisonsModel
    @State var churnPublisher: ChurnPublisher!
    @State private var selectedPeriod: TimeLord.PeriodTypes?
    @State private var selectedPeriodIndex: Int
    @State private var selectedTimeSlice: Timeslices?
    @State private var selectedTimeSliceIndex: Int
    
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
            if observation == nil {
                observation = ObservationsModel().insertRecord()
                observation?.observation2model = model
            }
            if model.model2lastlearningtimeslice == nil {
                model.model2lastlearningtimeslice = timeSlices.first
            }
            guard let selectedTimeSlice = model.model2lastlearningtimeslice else {
                fatalError("Error in grepping timeslice")
            }
            self.churnPublisher = ChurnPublisher(model: self.model)
            self.selectedTimeSlice = selectedTimeSlice
            let index = timeSlices.firstIndex(of: selectedTimeSlice)
            self.selectedTimeSliceIndex = index!
        } else {
            selectedTimeSliceIndex = 0
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
                            Text("Item 3")
                            Text("Item 4")
                        }
                    }
                    Button("Get Best of") {
                        ChurnPublisher(model: self.model).calculate(comparisonsDataModel: self.comparisonsDataModel)
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
    var model: Models
    var modelColumnsMap: Dictionary<String, String> = [:]
    var columnsDataModel: ColumnsModel
    @State private var sorting = [KeyPathComparator(\ComparisonsModel.ComparisonEntry.targetReportedStringValue)]
    init(model: Models, comparisonsDataModel: ComparisonsModel ) {
        self.model = model
        self.comparisonsDataModel = comparisonsDataModel
        columnsDataModel = ColumnsModel(model: self.model)
        modelColumnsMap["primaryKeyValue"] = columnsDataModel.primaryKeyColumn!.name!
        modelColumnsMap["timeBaseCount"] = columnsDataModel.timeStampColumn!.name!
        modelColumnsMap["targetReported"] = columnsDataModel.targetColumns.first!.name!
        modelColumnsMap["targetPredicted"] = "Predicted: " + columnsDataModel.targetColumns.first!.name!
    }
    var body: some View {
        let detailedItems = comparisonsDataModel.reportingDetails
        let summaryItems = comparisonsDataModel.reportingSummaries.sorted(by: { $0.primaryKeyValue < $1.primaryKeyValue})
        VStack {
            HStack {
                HStack {
                    Text("Rows count")
                    Text("\(summaryItems.count)")
                }
                Spacer()
                
            }.background(Color.green)
            Table(summaryItems, selection: $id, sortOrder: $sorting) {
                TableColumn("Reporting Date", value: \.reportingDateStringValue)
                TableColumn(modelColumnsMap["primaryKeyValue"]!, value: \.primaryKeyValue)
                TableColumn(modelColumnsMap["timeBaseCount"]!, value: \.timeBaseCountStringValue)
                TableColumn(modelColumnsMap[ "targetReported"]!, value: \.targetReportedStringValue)
                TableColumn(modelColumnsMap[ "targetPredicted"]!, value: \.targetPredictedStringValue)
                
            }
            Table(detailedItems.filter( { $0.primaryKeyValue == summaryItems.filter( { $0.id == id}).first?.primaryKeyValue})) {
                TableColumn("Reporting Date", value: \.reportingDateStringValue)
                TableColumn(modelColumnsMap["primaryKeyValue"]!, value: \.primaryKeyValue)
                TableColumn("TimeSlices", value: \.timeSlicesStringValue)
                TableColumn("LookAhead", value: \.lookAheadStringValue)
                TableColumn(modelColumnsMap["timeBaseCount"]!, value: \.timeBaseCountStringValue)
                TableColumn(modelColumnsMap[ "targetReported"]!, value: \.targetReportedStringValue)
                TableColumn(modelColumnsMap[ "targetPredicted"]!, value: \.targetPredictedStringValue)
            }
        }
        .onAppear {
            comparisonsDataModel.gather()
        }
    }
    
}
struct ModelsView_Previews: PreviewProvider {
    static var previews: some View {
        ModelsView(model: ModelsModel().items.first!)
    }
}


