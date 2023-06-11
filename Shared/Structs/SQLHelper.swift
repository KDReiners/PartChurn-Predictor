//
//  SQLHelper.swift
//  PartChurn Predictor
//
//  Created by Reiners, Klaus Dieter on 11.06.23.
//

import Foundation
import SwiftUI
struct SQLHelper {
    func runSQLCommand() {
        let fileManager = FileManager.default
        let odbcPath =  "/opt/homebrew/Cellar/mssql-tools18/18.2.1.1/bin/sqlcmd"
        let process = Process()
        let currentEnvironment = ProcessInfo.processInfo.environment
        process.environment = currentEnvironment.merging(["PATH": "\(odbcPath):\(currentEnvironment["PATH"] ?? "")"])
            { _, new in new }
        if fileManager.fileExists(atPath: odbcPath) {
            print ("file exists at path: \(odbcPath)")
            if fileManager.isReadableFile(atPath: odbcPath) {
                print("File is readable.")
            }
            if fileManager.isExecutableFile(atPath: odbcPath ) {
                    print("File is executable.")
            }
        } else {
            print("File does not exist.")
        }
        process.executableURL = URL(fileURLWithPath: odbcPath)
        process.arguments = [
            "-S",
            "EUDE82TAASQL003", // The name of your SQL Server
            "-U",
            "yourUsername", // Your username for the SQL Server
            "-P",
            "yourPassword", // Your password for the SQL Server
            "-Q",
            "SELECT * FROM yourTable" // Your SQL query
        ]
        
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            if let outputString = String(data: outputData, encoding: .utf8) {
                print(outputString)
            }
        } catch {
            print("Error executing SQL command: \(error)")
        }
    }
}

