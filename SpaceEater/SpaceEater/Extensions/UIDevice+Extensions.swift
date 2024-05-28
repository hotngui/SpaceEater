//
// Created by Joey Jarosz on 5/24/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import UIKit

extension UIDevice {
    var availableCapacityInBytes: Int64 {
        if let x = try? URL.homeDirectory.resourceValues(forKeys: [URLResourceKey.volumeAvailableCapacityKey]) {
            if let y = x.volumeAvailableCapacity {
                return Int64(y)
            }
        }
        return 0
    }
    
    var availableCapacityForImportantUsage: Int64 {
        if let x = try? URL.homeDirectory.resourceValues(forKeys: [URLResourceKey.volumeAvailableCapacityForImportantUsageKey]) {
            if let y = x.volumeAvailableCapacityForImportantUsage {
                return y
            }
        }
        return 0
    }
    
    var availableCapacityForOpportunisticUsage: Int64 {
        if let x = try? URL.homeDirectory.resourceValues(forKeys: [URLResourceKey.volumeAvailableCapacityForOpportunisticUsageKey]) {
            if let y = x.volumeAvailableCapacityForOpportunisticUsage {
                return y
            }
        }
        return 0
    }
    
    var totalDiskSpaceInBytes: Int64 {
        guard let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: URL.homeDirectory.path),
              let space = (systemAttributes[FileAttributeKey.systemSize] as? NSNumber)?.int64Value else {
            return 0
        }
        
        return space
    }
    
    var usedDiskSpaceInBytes: Int64 {
       return totalDiskSpaceInBytes - availableCapacityInBytes
    }
}
