//
// Created by Joey Jarosz on 5/24/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import Foundation

struct FileGenerator {
    static let defaultNumberOfFiles = 1
    static let defaultSizeOfFileInBytes = Measurement<UnitInformationStorage>(value: 100, unit: .megabytes).converted(to: .bytes).value
    
    func generate(numberOfFiles: Int, sizeOfFilesInBytes: Double) async throws {
        let pieces = sizeOfFilesInBytes / 10.0
        let timestamp = Date().timeIntervalSince1970
        var outputStr = ""
        
        for _ in 0..<Int64(pieces) {
            outputStr += "0123456789"
        }
        
        let data = Data(outputStr.utf8)
        
        for n in 0..<numberOfFiles {
            let name = "File_\(timestamp)_\(n)"
            let url = URL.documentsDirectory.appending(path: name)

            try data.write(to: url, options: [.atomic])
        }
    }
    
    func removeFiles(_ count: Int? = nil) async throws {
        let fm = FileManager.default
        let documentPath =  URL.documentsDirectory.path
        let fileNames = try fm.contentsOfDirectory(atPath: documentPath)
        var tally = 0
        
        for fileName in fileNames {
            if let count, tally >= count {
                break
            }
            
            try fm.removeItem(atPath: "\(documentPath)/\(fileName)")
            tally += 1
        }
    }
    
    // MARK: - Our Disk Space Usage
    
    func usedDisk() ->  Double {
        var size: Int64 = 0
        
        walkDirectory(at: URL.documentsDirectory, options: []) { sz in
            if let sz {
                size += sz
            }
        }
        
        return Double(size)
    }
    
    private func walkDirectory(at url: URL, options: FileManager.DirectoryEnumerationOptions, completion: ((Int64?) -> Void)) {
        let fm = FileManager.default
        let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: nil, options: options)
        
        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.hasDirectoryPath {
                walkDirectory(at: fileURL, options: options, completion: completion)
            } else {
                completion(fm.sizeOfFile(atPath: fileURL.path()))
            }
        }
    }

}
