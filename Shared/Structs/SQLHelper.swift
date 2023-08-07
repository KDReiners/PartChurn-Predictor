//
//  SQLHelper.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 11.06.23.
//

import Foundation
import SwiftUI
struct SQLHelper {
    func runSQLCommand(transferDirectory: URL, transferFileName: String = "MSNonsense.json") -> URL? {
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
            "set nocount on declare @json varchar(max) set @json = (select  * FROM sao.customer_m where dt_deleted is null and i_customer_m >0 for json auto) select @json",
            "-k",
            "-o",
            transferPath, // Set the full path to the output file
            "-y",
            "0"
        ]

        do {
            try process.run()
            process.waitUntilExit()

            // Return the URL of the output file
            return URL(fileURLWithPath: transferPath)
        } catch {
            print("Error executing SQL command: \(error)")
        }

        return nil
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






