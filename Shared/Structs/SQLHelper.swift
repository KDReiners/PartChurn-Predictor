//
//  SQLHelper.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 11.06.23.
//

import Foundation
import SwiftUI
struct SQLHelper {
    func runSQLCommand(completion: @escaping (String?) -> Void) {
        let odbcPath = "/opt/homebrew/Cellar/mssql-tools18/18.2.1.1/bin/sqlcmd"
        let batchSize = 10
        var outputData = Data()

        func runBatch(offset: Int) {
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
                "set nocount on declare @json varchar(max) set @json = (select * FROM sao.customer_m where dt_deleted is null and i_customer_m >0 order by i_customer_m offset \(offset) rows fetch next \(batchSize) rows only FOR JSON auto)select @json ",
                "-y",
                "0"
            ]

            let outputPipe = Pipe()
            process.standardOutput = outputPipe

            process.terminationHandler = { _ in
                let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
                outputData.append(data)
                print("empfange daten")

                if data.count < batchSize { // Reached the end of the result set
                    if let jsonString = String(data: outputData, encoding: .utf8) {
                        completion(jsonString)
                    } else {
                        completion(nil)
                    }
                } else {
                    runBatch(offset: offset + batchSize)
                }
            }

            do {
                try process.run()
            } catch {
                print(error)
                completion(nil)
            }
        }

        // Start fetching batches from offset 0
        runBatch(offset: 0)
    }
    func test() {
        runSQLCommand { jsonString in
            if let jsonString = jsonString {
                print(jsonString)
            } else {
                print("Failed to retrieve data from SQLCMD.")
            }
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

}





