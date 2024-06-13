// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

guard CommandLine.arguments.count >= 2 else {
    print("Error: Must provide a file to read from as first program argument")
    exit(-1)
}

let filePath = CommandLine.arguments[1]

let tocParser = TOCParser(file: filePath)
tocParser.compute()
