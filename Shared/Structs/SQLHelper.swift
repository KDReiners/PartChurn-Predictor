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
    func runSQLCommand(model: Models, transferFileName: String = "MSNonsense.json", sqlCommand: String) -> ([String: MLDataValueConvertible]?, [String]?) {
        var jsonArray: [[String: Any]]?
        var keys: [String] = []
        var tableData: [String: MLDataValueConvertible] = [:]
        let subDirectoryName = (transferFileName as NSString).deletingPathExtension
        let transferFileDirectory: URL = BaseServices.sandBoxDataPath.appendingPathComponent(model.name!).appendingPathComponent("Import", isDirectory: true).appendingPathComponent(subDirectoryName)
        BaseServices.createDirectory(at: transferFileDirectory)
        let odbcPath = "/opt/homebrew/Cellar/mssql-tools18/18.2.1.1/bin/sqlcmd"
        // Construct the output file path in the current working directory
        let transferPath = transferFileDirectory.appendingPathComponent(transferFileName).path
//        let transferPath = transferDirectory.appendingPathComponent(subDirectoryName.path, isDirectory: true).appendingPathComponent(transferFileName).path
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
            
            guard let data = try? Data(contentsOf: fileURL ) else {
                fatalError("Failed to read JSON file.")
            }
            do {
                let mydata = String(data: data, encoding: .utf8)
                let firstObjectString = mydata!.split(separator: "}")[0]
                let cleanedString = firstObjectString
                    .replacingOccurrences(of: "[", with: "")
                    .replacingOccurrences(of: "]", with: "")
                    .replacingOccurrences(of: "{", with: "")
                    .replacingOccurrences(of: "}", with: "")
                let keyValuePairStrings = cleanedString.components(separatedBy: ",")
                for keyValue in keyValuePairStrings {
                    let components = keyValue.components(separatedBy: ":")
                    if let firstComponent = components.first {
                        let key = firstComponent.trimmingCharacters(in: .whitespacesAndNewlines)
                        if key.first == "\"" && key.last == "\"" {
                            keys.append(String(key.dropFirst().dropLast()))
                        }
                    }
                }
                jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any ]]
            } catch {
                print("Error parsing JSON: \(error)")
            }
            
        } catch {
            print("Error executing SQL command: \(error)")
        }
        
        guard let jsonArray = jsonArray else { return (nil, nil) }

        var groupedDictionary: [String: [Any]] = [:]
        var startTime = Date()

        transformData(jsonArray) { result in
            let endTime = Date()
            let executionTime = endTime.timeIntervalSince(startTime)
            print("Execution time: \(executionTime) seconds")
            
            // Use the 'result' dictionary of arrays as needed
            print(result)
        }
        func transformData(_ dataArray: [[String: Any]], completion: @escaping ([[String: [Any]]]) -> Void) {
            var transformedDataArray: [[String: [Any]]] = []
            
            let queue = DispatchQueue(label: "com.example.transformQueue") // Serial queue

            DispatchQueue.concurrentPerform(iterations: dataArray.count) { index in
                let dict = dataArray[index]
                var transformedDict: [String: [Any]] = [:]
                
                for (key, value) in dict {
                    transformedDict[key] = [value]
                }
                
                queue.sync {
                    transformedDataArray.append(transformedDict)
                }
            }
            
            completion(transformedDataArray)
        }
        let combinedDict = jsonArray.reduce(into: [String: [Any]]()) { result, dict in
            for (key, value) in dict {
                if var values = result[key] {
                    values.append(value)
                    result[key] = values
                } else {
                    result[key] = [value]
                }
            }
        }
        var endTime = Date()
        var executionTime = endTime.timeIntervalSince(startTime)
        startTime = Date()
        for dictionary in jsonArray {
            for (key, value) in dictionary {
                if let existingValues = groupedDictionary[key] {
                    groupedDictionary[key] = existingValues + [value]
                } else {
                    groupedDictionary[key] = [value]
                }
            }
        }
        endTime = Date()
        executionTime = endTime.timeIntervalSince(startTime)
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
        do {
            let mlDataTable = try MLDataTable(dictionary: tableData)
            BaseServices.saveMLDataTableToJson(mlDataTable: mlDataTable, filePath: transferFileDirectory)
        } catch {
            print("mlDataTable could not be instantiated: \(error.localizedDescription)")
        }
        return (tableData, keys)
    }
}






