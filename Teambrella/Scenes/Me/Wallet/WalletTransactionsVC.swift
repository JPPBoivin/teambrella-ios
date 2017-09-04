//
//  WalletTransactionsVC.swift
//  Teambrella
//
//  Created by Екатерина Рыжова on 01.09.17.
//  Copyright © 2017 Yaroslav Pasternak. All rights reserved.
//

import UIKit

class WalletTransactionsVC: UIViewController, Routable {
    
    static let storyboardName = "Me"
    
    var teamID: Int?
    var dataSource: WalletTransactionsDataSource!
    fileprivate var previousScrollOffset: CGFloat = 0

    @IBOutlet var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addGradientNavBar()
        title = "Me.WalletVC.WalletTransactionsVC.title".localized
        collectionView.register(WalletTransactionCell.nib, forCellWithReuseIdentifier: WalletTransactionCell.cellID)
        guard let teamID = teamID else { return }
        
        dataSource = WalletTransactionsDataSource(teamID: teamID)
        dataSource.onUpdate = { [weak self] in
            self?.collectionView.reloadData()
        }
        dataSource.loadData()
    }
}

// MARK: UICollectionViewDataSource
extension WalletTransactionsVC: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: WalletTransactionCell.cellID, for: indexPath)
    }
}

// MARK: UICollectionViewDelegate
extension WalletTransactionsVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        WalletTransactionsCellBuilder.populate(cell: cell, with: dataSource[indexPath])
        if indexPath.row == (dataSource.count - dataSource.limit/2) {
            dataSource.loadData()
        }
    }
}

// MARK: UICollectionViewDelegateFlowLayout
extension WalletTransactionsVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height/5 )
    }
}

// MARK: UIScrollViewDelegate
extension WalletTransactionsVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset.y
        previousScrollOffset = currentOffset
    }
}
