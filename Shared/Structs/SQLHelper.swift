//
//  SQLHelper.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 11.06.23.
//

import Foundation
import SwiftUI
import CreateML
struct SQLHelper {
    func runSQLCommand(model: Models, transferFileName: String = "MSNonsense.json", sqlCommand: String) -> [String: MLDataValueConvertible]? {
        var jsonArray: [[String: Any]]?
        var tableData: [String: MLDataValueConvertible] = [:]
        let transferDirectory: URL = BaseServices.sandBoxDataPath
        let odbcPath = "/opt/homebrew/Cellar/mssql-tools18/18.2.1.1/bin/sqlcmd"
        // Construct the output file path in the current working directory
        let transferPath = transferDirectory.appendingPathComponent(transferFileName).path
        let process = Process()
        process.executableURL = URL(fileURLWithPath: odbcPath)
        process.arguments = [
            "-S",
            "10.49.6.37", // The name of your SQL Server
            "-d",
            "WAC",
            "-U",
            "sa", // Your username for the SQL Server
            "-P",
            "!SqL!2015&T@@&", // Your password for the SQL Server
            "-N",
            "-C",
            "-Q",
            "\(sqlCommand)",
            "-k",
            "-o",
            transferPath, // Set the full path to the output file
            "-y",
            "0"
        ]
        
        do {
            try process.run()
            process.waitUntilExit()
            let fileURL = URL(fileURLWithPath: transferPath)
            print(fileURL)
            guard let data = try? Data(contentsOf: fileURL ) else {
                fatalError("Failed to read JSON file.")
            }
            do {
                jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any ]]
            } catch {
                print("Error parsing JSON: \(error)")
            }
            
        } catch {
            print("Error executing SQL command: \(error)")
        }
        guard let jsonArray = jsonArray else { return nil }
        var groupedDictionary: [String: [Any]] = [:]
        for dictionary in jsonArray {
            for (key, value) in dictionary {
                if let existingValues = groupedDictionary[key] {
                    groupedDictionary[key] = existingValues + [value]
                } else {
                    groupedDictionary[key] = [value]
                }
            }
        }
        for (key, values) in groupedDictionary {
            if values.allSatisfy( {$0 as? Int != nil}) {
                tableData[key] = values.map {$0 as! Int }
                continue
            }
            if values.allSatisfy( {$0 as? Double != nil}) {
                tableData[key] = values.map {$0 as! Double }
                continue
            }
            if values.allSatisfy( {$0 as? String != nil}) {
                tableData[key] = values.map {$0 as! String }
                continue
            }
            
        }
        return tableData
    }
}
    
    

func readJSONFromPipe(outputData: String?) {
    guard let outputData = outputData else {
        print("No JSON data received.")
        return
    }
    // Parse the JSON data as an array of dictionaries
    do {
        if let jsonArray = try JSONSerialization.jsonObject(with: (outputData.data(using: .utf8))!, options: [  ]) as? [[String: Any]] {
            // Process the JSON array here
            for jsonObject in jsonArray {
                if let s_custno = jsonObject["s_custno"] as? String {
                    print(s_custno)
                }
            }
        } else {
            print("Failed to parse JSON.")
        }
    } catch {
        print("Error parsing JSON: \(error)")
    }
}






