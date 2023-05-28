//
//  JsonProvider.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 27.05.23.
//

import Foundation
import CreateML

// Funktion zum Speichern der MLDATATable in JSON
func saveMLDataTableToJson(mlDataTable: MLDataTable, filePath: URL) {
    try? mlDataTable.write(to: filePath)
    let newTable = loadMLDataTableFromJson(filePath: filePath)
    print(newTable!)
}

// Funktion zum Laden der MLDATATable aus JSON
func loadMLDataTableFromJson(filePath: URL) -> MLDataTable? {
    var result: MLDataTable?
    do {
        result  = try MLDataTable(contentsOf: filePath)
    } catch {
        print("No model is stored yet.")
    }
    return result;
}
