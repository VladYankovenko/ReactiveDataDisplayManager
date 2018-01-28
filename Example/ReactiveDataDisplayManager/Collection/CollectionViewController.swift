
//
//  CollectionViewController.swift
//  ReactiveDataDisplayManagerExample
//
//  Created by Ivan Smetanin on 27/01/2018.
//  Copyright © 2018 Alexander Kravchenkov. All rights reserved.
//

import UIKit
import ReactiveDataDisplayManager

class CollectionViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet private weak var collectionView: UICollectionView!

    // MARK: - Properties

    private lazy var adapter = BaseCollectionDataDisplayManager()
    private lazy var titles: [String] = ["One", "Two", "Three", "Four"]

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        configureAdapter()
        fillAdapter()
    }

    // MARK: - Private methods

    /// This method is used to configure table adapter and set table delegate and data source
    private func configureAdapter() {
        adapter.set(collection: collectionView)
    }

    /// This method is used to fill adapter
    private func fillAdapter() {
        for title in titles {
            // Create generator
            let generator = TitleCollectionGenerator(model: title)
            generator.didSelectEvent += {
                debugPrint("\(title) selected")
            }
            // Add generator to adapter
            adapter.addCellGenerator(generator)
        }

        // Tell adapter that we've changed generators
        adapter.didRefill()
    }

}
