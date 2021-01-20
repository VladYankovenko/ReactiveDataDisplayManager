//
//  GravityTableStateManager.swift
//  ReactiveDataDisplayManager
//
//  Created by Aleksandr Smirnov on 23.11.2020.
//  Copyright © 2020 Александр Кравченков. All rights reserved.
//

import Foundation

public protocol Gravity: AnyObject {
    var heaviness: Int { get set }

    func getHeaviness() -> Int
}

extension EmptyGravityTableHeaderGenerator: Gravity {
    public var heaviness: Int {
        get {
            return self.getHeaviness()
        }
        set {
            fatalError()
        }
    }
}


open class GravityTableStateManager {

    // MARK: - Properties

    weak var adapter: TableAdapter?

    public var generators: [[GravityTableCellGenerator]]
    public var sections: [GravityTableHeaderGenerator]

    // MARK: - Initialization and deinitialization

    public init() {
        self.generators = [[GravityTableCellGenerator]]()
        self.sections = [GravityTableHeaderGenerator]()
    }

    // MARK: - Public methods

    public func forceRefill() {
        adapter?.tableView.reloadData()
    }

    public func forceRefill(completion: @escaping (() -> Void)) {
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            completion()
        }
        self.forceRefill()
        CATransaction.commit()
    }

    public func addCellGenerator(_ generator: GravityTableCellGenerator) {
        guard
            checkDuplicate(generator: generator),
            let tableView = self.adapter?.tableView
        else {
            return
        }

        generator.registerCell(in: tableView)

        if generators.count != sections.count || sections.isEmpty {
            generators.append([GravityTableCellGenerator]())
        }

        if sections.isEmpty {
            sections.append(EmptyGravityTableHeaderGenerator())
        }

        let index = sections.count - 1
        let currentIndex = index < 0 ? 0 : index
        generators[currentIndex].append(generator)

        insert(generators: [generator], to: currentIndex)
    }

    public func addCellGenerators(_ generators: [GravityTableCellGenerator], after: GravityTableCellGenerator) {
        generators.reversed().forEach { self.addCellGenerator($0, after: after) }
    }

    public func addCellGenerator(_ generator: GravityTableCellGenerator, after: GravityTableCellGenerator) {

        guard
            let path = indexPath(for: after)
        else {
            assertionFailure("Generator doesn't exist")
            return
        }

        generators[path.section].insert(generator, at: path.row + 1)

        generator.heaviness = after.heaviness + 1
        generators[path.section].forEach { gen in
            guard gen.heaviness > generator.heaviness else { return }
            gen.heaviness += 1
        }

        insert(generators: [generator], to: path.section)
    }

    public func addCellGenerators(_ generators: [GravityTableCellGenerator]) {
        generators.forEach { self.addCellGenerator($0) }
    }

    public func update(generators: [GravityTableCellGenerator]) {
        let indexPaths = generators.compactMap { self.indexPath(for: $0) }
        adapter?.tableView.reloadRows(at: indexPaths, with: .none)
    }

    public func clearCellGenerators() {
        generators.removeAll()
    }

    // MARK: - HeaderDataDisplayManager

    public func addSectionHeaderGenerator(_ generator: GravityTableHeaderGenerator) {
        checkDuplicate(header: generator)
        sections.append(generator)

        if generators.count != sections.count || sections.isEmpty {
            generators.append([GravityTableCellGenerator]())
        }

        let combined = zip(sections, generators).sorted { lhs, rhs in
            lhs.0.getHeaviness() < rhs.0.getHeaviness()
        }

        sections = combined.map { $0.0 }
        generators = combined.map { $0.1 }
    }

    public func addCellGenerator(_ generator: GravityTableCellGenerator, toHeader header: GravityTableHeaderGenerator) {
        guard checkDuplicate(generator: generator) else { return }
        addCellGenerators([generator], toHeader: header)
    }

    public func addCellGenerators(_ generators: [GravityTableCellGenerator], toHeader header: GravityTableHeaderGenerator) {
        guard let tableView = self.adapter?.tableView else { return }

        generators.forEach { $0.registerCell(in: tableView) }

        if self.generators.count != sections.count || sections.isEmpty {
            self.generators.append([GravityTableCellGenerator]())
        }

        if let index = sections.firstIndex(where: { $0 === header }) {
            self.generators[index].append(contentsOf: generators)
            insert(generators: generators, to: index)
        }
    }

    public func removeAllGenerators(from header: GravityTableHeaderGenerator) {
        guard
            let index = self.sections.index(where: { $0 === header }),
            self.generators.count > index
        else {
            return
        }

        self.generators[index].removeAll()
    }


    public func clearHeaderGenerators() {
        sections.removeAll()
    }

    open func replace(oldGenerator: GravityTableCellGenerator,
                 on newGenerator: GravityTableCellGenerator,
                 removeAnimation: UITableView.RowAnimation = .automatic,
                 insertAnimation: UITableView.RowAnimation = .automatic) {
        guard let index = self.findGenerator(oldGenerator), let table = self.adapter?.tableView else { return }

        table.beginUpdates()
        self.generators[index.sectionIndex].remove(at: index.generatorIndex)
        self.generators[index.sectionIndex].insert(newGenerator, at: index.generatorIndex)
        let indexPath = IndexPath(row: index.generatorIndex, section: index.sectionIndex)
        table.deleteRows(at: [indexPath], with: removeAnimation)
        table.insertRows(at: [indexPath], with: insertAnimation)
        table.endUpdates()
    }

    open func replace(header: GravityTableHeaderGenerator, with animation: UITableView.RowAnimation = .fade) {
        guard let indexOfHeader = self.sections.firstIndex(where: { $0 === header }) else {
            self.addSectionHeaderGenerator(header)
            return
        }

        self.sections[indexOfHeader] = header
        self.adapter?.tableView.reloadSections(IndexSet(arrayLiteral: indexOfHeader), with: animation)
    }

    open func remove(_ generator: GravityTableCellGenerator,
                              with animation: UITableView.RowAnimation = .automatic,
                              needScrollAt scrollPosition: UITableView.ScrollPosition? = nil,
                              needRemoveEmptySection: Bool = false) {
        guard let index = self.findGenerator(generator) else { return }
        self.removeGenerator(with: index,
                             with: animation,
                             needScrollAt: scrollPosition,
                             needRemoveEmptySection: needRemoveEmptySection)
    }
}

private extension GravityTableStateManager {

    func checkDuplicate(header: GravityTableHeaderGenerator) {
        guard
            !sections.contains(where: { $0.getHeaviness() == header.getHeaviness() })
        else {
            assertionFailure("Unique heaviness expected for \(header)")
            return
        }
    }

    func checkDuplicate(generator: GravityTableCellGenerator) -> Bool {
        return !generators.contains(where: { section in
            section.contains { $0.heaviness == generator.heaviness }
        })
    }

    func insert(generators: [GravityTableCellGenerator], to section: Int) {
        guard !generators.isEmpty else { return }

        self.generators[section].sort { $0.heaviness < $1.heaviness }

        let indexPaths = generators.compactMap { generator -> IndexPath? in
            guard
                let index = self.nearestIndex(for: generator, in: section)
            else {
                return nil
            }
            return IndexPath(row: index, section: section)
        }

        adapter?.tableView.insertRows(at: indexPaths, with: .none)
    }

    func nearestIndex(for generator: GravityTableCellGenerator, in section: Int) -> Int? {
        let nearestIndex = generators[section].enumerated().min { lhs, rhs in
            let lhsValue = abs(lhs.element.heaviness - generator.heaviness)
            let rhsValue = abs(rhs.element.heaviness - generator.heaviness)
            return lhsValue < rhsValue
        }

        return nearestIndex?.offset
    }

    func indexPath(for generator: GravityTableCellGenerator) -> IndexPath? {
        for (sectionIndex, section) in generators.enumerated() {
            if let generatorIndex = section.firstIndex(where: { $0 === generator }) {
                return IndexPath(row: generatorIndex, section: sectionIndex)
            }
        }

        return nil
    }

    func findGenerator(_ generator: TableCellGenerator) -> (sectionIndex: Int, generatorIndex: Int)? {
        for (sectionIndex, section) in generators.enumerated() {
            if let generatorIndex = section.firstIndex(where: { $0 === generator }) {
                return (sectionIndex, generatorIndex)
            }
        }
        return nil
    }

    // TODO: May be we should remove needScrollAt and move this responsibility to user
    func removeGenerator(with index: (sectionIndex: Int, generatorIndex: Int),
                         with animation: UITableView.RowAnimation = .automatic,
                         needScrollAt scrollPosition: UITableView.ScrollPosition? = nil,
                         needRemoveEmptySection: Bool = false) {
        guard let table = self.adapter?.tableView else { return }

        // perform update
        table.beginUpdates()
        self.generators[index.sectionIndex].remove(at: index.generatorIndex)
        let indexPath = IndexPath(row: index.generatorIndex, section: index.sectionIndex)
        table.deleteRows(at: [indexPath], with: animation)

        // scroll if needed
        if let scrollPosition = scrollPosition {
            table.scrollToRow(at: indexPath, at: scrollPosition, animated: true)
        }

        table.endUpdates()
    }

}