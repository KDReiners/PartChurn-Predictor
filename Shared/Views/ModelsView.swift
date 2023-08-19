//
//  ModelsView.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 17.08.23.
//

import SwiftUI
import CoreData

struct ModelsView: View {
    var modelDataModel = ModelsModel()
    var model: Models
    init(model: Models) {
        self.model = model
    }
    var body: some View {
        Text("hello")
    }
}

struct ModelsView_Previews: PreviewProvider {
    static var previews: some View {
        ModelsView(model: ModelsModel().items.first!)
    }
}

