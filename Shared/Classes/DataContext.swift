//
//  DataContext.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 06.07.23.
//

import Foundation
class DataContext: ObservableObject, AsyncOperationDelegate {

    var mlDataTableProviderContext: SimulationController.MlDataTableProviderContext
    @Published var upDated = true
    func asyncOperationDidFinish<T>(withResult result: T) {
        print("ASYNC Finished")
        upDated = true
    }
    init (mlDataTableProviderContext: SimulationController.MlDataTableProviderContext) {
        self.mlDataTableProviderContext = mlDataTableProviderContext
    }
}

