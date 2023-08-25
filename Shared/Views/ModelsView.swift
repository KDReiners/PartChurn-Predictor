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
    var timeslicesDataModel = TimeSliceModel()
    var model: Models
    @State private var selectedPeriod: TimeLord.PeriodTypes?
    @State private var selectedPeriodIndex: Int
    let periodLabels = ["Year", "Half Year", "Quarter", "Month"]
    
    @State private var selectedTimeSlice: Timeslices?
    @State private var selectedTimeSliceIndex: Int
    
    
    var timeSlices: [Timeslices] = []
    init(model: Models) {
        self.model = model
        timeSlices = timeslicesDataModel.items.filter( { $0.timeslice2models == model} )
        timeSlices.sort(by: { $0.value < $1.value })
        self.selectedPeriodIndex = Int(model.periodtype)
        
        if !timeSlices.isEmpty {
            if model.model2lastLearningTimeSlice == nil {
                model.model2lastLearningTimeSlice = timeSlices.first
            }
            guard let selectedTimeSlice = model.model2lastLearningTimeSlice else {
                fatalError("Error in grepping timeslice")
            }
            self.selectedTimeSlice = selectedTimeSlice
            let index = timeSlices.firstIndex(of: selectedTimeSlice)
            self.selectedTimeSliceIndex = index!
        } else {
            selectedTimeSliceIndex = 0
        }
        
        
           
        
    }
    var body: some View {
        
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 20) {
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
                            self.model.model2lastLearningTimeSlice = selectedTimeSlice
                            BaseServices.save()
                        }
                    }
                    .background(Color.white)
                    .frame(maxWidth: geometry.size.width * 0.5, alignment: .topLeading)
                    
                    GroupBox(label: Text("Learning").font(.title)) {
                        Text("Item 3")
                        Text("Item 4")
                    }
                }.background(Color.white)
            }
            .frame(maxWidth: geometry.size.width * 0.5, alignment: .topLeading)
            .background(Color.white)
            .padding()
        }
        .background(Color.white)
    }
}

struct ModelsView_Previews: PreviewProvider {
    static var previews: some View {
        ModelsView(model: ModelsModel().items.first!)
    }
}



