//
//  ClaimTransactionsDataSource.swift
//  Teambrella
//
//  Created by Екатерина Рыжова on 29.08.17.
//  Copyright © 2017 Yaroslav Pasternak. All rights reserved.
//

import Foundation

class ClaimTransactionsDataSource {
    var items: [ClaimTransactionsCellModel] = []
    var count: Int { return items.count }
    let teamID: Int
    let claimID: Int
    let limit: Int = 100
    var search: String = "Cleopatra"
    
    var onUpdate: (() -> Void)?
    var onError: ((Error) -> Void)?
    
    init(teamID: Int, claimID: Int) {
        self.teamID = teamID
        self.claimID = claimID
    }
    
    subscript(indexPath: IndexPath) -> ClaimTransactionsCellModel {
        let model = items[indexPath.row]
        return model
    }
    
    func loadData() {
        service.server.updateTimestamp { [weak self] timestamp, error in
            let key = Key(base58String: ServerService.privateKey,
                          timestamp: timestamp)
            guard let teamId = self?.teamID, let claimId = self?.claimID,
                let offset = self?.count, let limit = self?.limit, let search = self?.search else { return }
            
            let body = RequestBody(key: key, payload:["TeamId": teamId,
                                                      "ClaimId": claimId,
                                                      "Limit": limit,
                                                      "Offset": offset,
                                                      "Search": search])
            let request = TeambrellaRequest(type: .claimTransactions, body: body, success: { [weak self] response in
                if case .claimTransactions(let transactions) = response {
                    self?.items += transactions
                    self?.onUpdate?()
                }
                }, failure: { [weak self] error in
                    self?.onError?(error)
            })
            request.start()
        }
    }
    
}
