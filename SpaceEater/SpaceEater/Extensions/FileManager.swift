//
// Created by Joey Jarosz on 5/26/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import Foundation

extension FileManager {
    func sizeOfFile(atPath path: String) -> Int64? {
            guard let attrs = try? attributesOfItem(atPath: path) else {
                return nil
            }

            return attrs[.size] as? Int64
    }
}

