//
//  TableLastCellIsVisiblePlugin.swift
//  ReactiveDataDisplayManager
//
//  Created by Никита Коробейников on 28.01.2021.
//  Copyright © 2021 Александр Кравченков. All rights reserved.
//

public class TableLastCellIsVisiblePlugin: PluginAction<TableEvent, BaseTableStateManager> {

    private let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    override func process(event: TableEvent, with manager: BaseTableStateManager?) {

        switch event {
        case .willDisplayCell(let indexPath):
            guard let generators = manager?.generators else {
                return
            }
            let lastSectionIndex = generators.count - 1
            let lastCellInLastSectionIndex = generators[lastSectionIndex].count - 1

            let lastCellIndexPath = IndexPath(row: lastCellInLastSectionIndex, section: lastSectionIndex)
            if indexPath == lastCellIndexPath {
                action()
            }
        default:
            break
        }
    }

}