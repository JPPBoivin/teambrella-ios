//
//  CompareTeamRiskVC.swift
//  Teambrella
//
//  Created by Екатерина Рыжова on 11.07.17.
//  Copyright © 2017 Yaroslav Pasternak. All rights reserved.
//

import UIKit

class CompareTeamRiskVC: UIViewController {

    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var searchBar: UISearchBar!
    
    let dataSource = MembersDatasource(orderByRisk: true)
    lazy var router: MembersRouter = MembersRouter()
    var ranges: [RiskScaleEntity.Range] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerCells()
        
        dataSource.loadData()
        dataSource.onUpdate = {
            self.collectionView.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func registerCells() {
        collectionView.register(InfoHeader.nib,
                                forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
                                withReuseIdentifier: InfoHeader.cellID)
        collectionView.register(RiskCell.nib, forCellWithReuseIdentifier: RiskCell.cellID)
    }
}

extension CompareTeamRiskVC: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.sections
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.itemsInSection(section: section)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: RiskCell.cellID, for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader,
                                                               withReuseIdentifier: InfoHeader.cellID,
                                                               for: indexPath)
    }
}

extension CompareTeamRiskVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        let model = dataSource[indexPath]
        if let cell = cell as? RiskCell {
            cell.nameLabel.text = model.name
            cell.avatar.showAvatar(string: model.avatar)
            cell.itemLabel.text = model.model
            cell.riskLabel.text = String(model.risk)
        }
    }
}

extension CompareTeamRiskVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 375, height: 71)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
       return CGSize(width: 375, height: 40)
    }
}
