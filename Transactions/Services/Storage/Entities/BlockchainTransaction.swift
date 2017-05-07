//
//  BlockchainTransaction.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 19.04.17.
//  Copyright © 2017 Yaroslav Pasternak. All rights reserved.
//

import CoreData

class BlockchainTransaction: NSManagedObject {
    var kind: TransactionKind? { return TransactionKind(rawValue: Int(kindValue)) }
    var resolution: TransactionClientResolution? {
        return TransactionClientResolution(rawValue: Int(resolutionValue))
    }
    var state: TransactionState? { return TransactionState(rawValue: Int(stateValue)) }
    var claimID: Int { return Int(claimIDValue) }
    var withdrawReqID: Int { return Int(withdrawReqIDValue) }
    var amount: Decimal { return amountValue! as Decimal }
    var fee: Decimal? { return feeValue as Decimal? }
    var id: UUID { return  UUID(uuidString: idValue!)! }
    var moveToAddressID: String? { return moveToAddressIDValue }
    var isServerUpdateNeeded: Bool { return isServerUpdateNeededValue }
    var clientResolutionTime: Date? { return clientResolutionTimeValue as Date? }
    var initiatedTime: Date? { return initiatedTimeValue as Date? }
    var processedTime: Date? { return processedTimeValue as Date? }
    var receivedTime: Date? { return receivedTimeValue as Date? }
    var updateTime: Date? { return updateTimeValue as Date? }
}

extension BlockchainTransaction {
    class func fetch(id: String, in context: NSManagedObjectContext) -> BlockchainTransaction? {
        let request: NSFetchRequest<BlockchainTransaction> = BlockchainTransaction.fetchRequest()
        request.predicate = NSPredicate(format: "idValue = %@", id)
        let result = try? context.fetch(request)
        return result?.first
    }
}
