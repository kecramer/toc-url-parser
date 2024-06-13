import Foundation

public class TOCParser {
    let filePath: String, filePointer: UnsafeMutablePointer<FILE>
    var lineBuf: UnsafeMutablePointer<CChar>? = nil, lineCap: Int = 0, lineNum: Int = 1, outputArray: [Int] = []
    var urls: [String: String] = [:]
    
    public init(file: String) {
        filePath = file
        guard FileManager.default.fileExists(atPath: filePath) else {
            print("Error: No file exists at [\(filePath)]")
            exit(-1)
        }

        // https://stackoverflow.com/questions/31778700/read-a-text-file-line-by-line-in-swift
        guard let filePointer: UnsafeMutablePointer<FILE> = fopen(filePath, "r") else {
            print("Error: Could not open file at [\(filePath)]")
            exit(-1)
        }
        
        self.filePointer = filePointer
    }
    
    deinit {
        fclose(filePointer)
        lineBuf?.deallocate()
    }
    
    public func compute() {
        var bytesRead = getline(&lineBuf, &lineCap, filePointer)

        while bytesRead > 0 { // Read every line in file -> O(k)
            let lineAsData = Data(bytes: lineBuf!, count: bytesRead-2) // Drop the trailing comma and new-line
            guard let reportingStructureLine: ReportingStructure = try? JSONDecoder().decode(ReportingStructure.self, from: lineAsData) else {
                print("Warning: Skipping line [\(lineNum)] because it is not convertible to a ReportingStructure")
                bytesRead = getline(&lineBuf, &lineCap, filePointer)
                lineNum += 1
                continue
            }

            if let inNetworkFiles = reportingStructureLine.in_network_files {
                for inNetworkFile in inNetworkFiles {
                    urls[inNetworkFile.location] = inNetworkFile.location
                }
            }

            if let allowedAmountFile = reportingStructureLine.allowed_amount_file {
                urls[allowedAmountFile.location] = allowedAmountFile.location
            }

            bytesRead = getline(&lineBuf, &lineCap, filePointer)
            lineNum += 1
        }

        for (_, url) in urls {
            let urlPart = url.prefix(100) // Reduce our search space
            for code in NewYorkCodes {
                if urlPart.contains("_\(code)_") {
                    print(url)
                }
            }
        }
    }
    
    func convertLineToJSON(bytes: UnsafeMutablePointer<CChar>?) -> Int? {
        let line = String.init(cString: bytes!).trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let numberOnLine = Int(line) else {
            return nil
        }
        
        return numberOnLine
    }
}

struct TOCFile : Codable {
    let reporting_entity_name: String
    let reporting_entity_type: String
    let reporting_structure: [ReportingStructure]
    let version: String
}

struct ReportingStructure : Codable {
    let reporting_plans: [ReportingPlans]
    let in_network_files: [FileLocationObject]?
    let allowed_amount_file: FileLocationObject?
}

struct ReportingPlans : Codable {
    let plan_name: String
    let plan_id_type: String
    let plan_id: String
    let plan_market_type: String
}

struct FileLocationObject : Codable {
    let description: String
    let location: String
}

enum PlanIdType : String {
    case EIN = "EIN"
    case HIOS = "HIOS"
}

enum PlanMarketType : String, Codable {
    case group = "group"
    case individual = "individual"
}

enum StateCodes : String, Codable {
    case NewYork = "254_39F0" // 254_39B0, 301_71B0, 301_71A0, 302_42B0, 302_42F0, 800_72A0, 800_72B0
}

// let NewYorkCodes: [String] = ["254_39F0", "254_39B0", "301_71B0", "301_71A0", "302_42B0", "302_42F0", "800_72A0", "800_72B0"]
let NewYorkCodes: [String] = ["254", "301", "302", "800"]