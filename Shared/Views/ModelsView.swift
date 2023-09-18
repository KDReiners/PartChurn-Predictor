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
    @ObservedObject var comparisonDataModel: ComparisonsModel
    @State var churnPublisher: ChurnPublisher!
    @State private var selectedPeriod: TimeLord.PeriodTypes?
    @State private var selectedPeriodIndex: Int
    let periodLabels = ["Year", "Half Year", "Quarter", "Month"]
    @State private var selectedTimeSlice: Timeslices?
    @State private var selectedTimeSliceIndex: Int
    var modelColumnsMap: Dictionary<String, String> = [:]
    var timeSlices: [Timeslices] = []
    var columnsDataModel: ColumnsModel
    
    init(model: Models) {
        self.model = model
        columnsDataModel = ColumnsModel(model: self.model)
        modelColumnsMap["primaryKeyValue"] = columnsDataModel.primaryKeyColumn!.name!
        modelColumnsMap["timeBaseCount"] = columnsDataModel.timeStampColumn!.name!
        modelColumnsMap["targetReported"] = columnsDataModel.targetColumns.first!.name!
        modelColumnsMap["targetPredicted"] = "Predicted: " + columnsDataModel.targetColumns.first!.name!
        comparisonDataModel = ComparisonsModel(model: self.model)
        timeSlices = timeslicesDataModel.items.filter( { $0.timeslice2models == model} )
        timeSlices.sort(by: { $0.value < $1.value })
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
        let detailedItems = comparisonDataModel.reportingDetails
        let summaryItems = comparisonDataModel.reportingSummaries
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
                        ChurnPublisher(model: self.model).calculate(comparisonsDataModel: self.comparisonDataModel)
                    }
        }.padding()
        Spacer()
        Table(summaryItems) {
            TableColumn("Reporting Date", value: \.reportingDateStringValue)
            TableColumn(modelColumnsMap["primaryKeyValue"]!, value: \.primaryKeyValue)
            TableColumn(modelColumnsMap["timeBaseCount"]!, value: \.timeBaseCountStringValue)
            TableColumn(modelColumnsMap[ "targetReported"]!, value: \.targetReportedStringValue)
            TableColumn(modelColumnsMap[ "targetPredicted"]!, value: \.targetPredictedStringValue)
            
        }
        .frame(alignment: .topLeading)
        .padding()
        .onAppear {
            comparisonDataModel.gather()
        }
        .background(Color.white)
    }
}

struct ModelsView_Previews: PreviewProvider {
    static var previews: some View {
        ModelsView(model: ModelsModel().items.first!)
    }
}


