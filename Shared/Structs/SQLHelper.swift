//
//  SQLHelper.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 11.06.23.
//

import Foundation
import SwiftUI
struct SQLHelper {
    func runSQLCommand() -> String? {
        var outputData = Data()
        let odbcPath = "/opt/homebrew/Cellar/mssql-tools18/18.2.1.1/bin/sqlcmd"
        let process = Process()
        var currentEnvironment = ProcessInfo.processInfo.environment
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
            "set nocount on declare @json varchar(max) set @json = (select top 2000 s_custno FROM sao.customer_m where dt_deleted is null and i_customer_m >0  FOR JSON auto)select @json ",
            "-k",
            "-y",
            "0"
        ]
        
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let bufferSize = 1024 // Adjust the buffer size as needed
            var tempBuffer = Data(capacity: bufferSize)
            
            repeat {
                if let bytesRead = try! outputPipe.fileHandleForReading.read(upToCount: bufferSize) {
                    if bytesRead.count > 0 {
                        tempBuffer = bytesRead
                        outputData.append(tempBuffer)
                    } else {
                        break
                    }
                } else {
                    break
                }
            } while true
            
            
        } catch {
            print(error)
        }
        let outputString = String(data: outputData, encoding: .utf8)
        return outputString
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





