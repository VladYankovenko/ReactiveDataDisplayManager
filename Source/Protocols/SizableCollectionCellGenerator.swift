//
//  HeightCollectionCellGenerator.swift
//  ReactiveDataDisplayManager
//
//  Created by Alexander Filimonov on 02/03/2020.
//  Copyright © 2020 Александр Кравченков. All rights reserved.
//

import UIKit

/// Generator that describes collection cell generator that can returns size
public protocol SizableCollectionCellGenerator: class {
    func getSize() -> CGSize
}
