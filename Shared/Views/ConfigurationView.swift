//
//  ConfigurationView.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 16.07.23.
//

import SwiftUI

struct ConfigurationView: View {
    @ObservedObject private var configuration = Configuration()
    var model: Models!
    init(model: Models?, activeLink: DirectoryView.ActiveLink? ) {
        guard let activeLink = activeLink else {
            return
        }
        if model != nil && activeLink == .configuration {
            configuration.model = model
            configuration.getStatistics()
        }
    }
    var body: some View {
        VStack() {
            StatisticsView(configuration: configuration)
        }
    }
}

struct ConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigurationView(model: ModelsModel().items.first!, activeLink: .configuration)
    }
}
