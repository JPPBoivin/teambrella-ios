//
//  WalletCellModels.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 23.06.17.
//  Copyright © 2017 Yaroslav Pasternak. All rights reserved.
//

import Foundation

protocol WalletCellModel {
    
}

struct WalletHeaderCellModel: WalletCellModel {
    let amount: Double
    let reserved: Double
    let available: Double
}

struct WalletFundingCellModel: WalletCellModel {
    let maxCoverageFunding: Double
    let uninterruptedCoverageFundingh: Double
}

struct WalletButtonsCellModel: WalletCellModel {
    let avatars: [String]
}
