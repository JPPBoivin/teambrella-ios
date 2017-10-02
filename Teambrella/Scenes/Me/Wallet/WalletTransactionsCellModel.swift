//
//  WalletTransactionsCellModel.swift
//  Teambrella
//
//  Created by Екатерина Рыжова on 02.09.17.
/* Copyright(C) 2017  Teambrella, Inc.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License(version 3) as published
 * by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see<http://www.gnu.org/licenses/>.
 */
//

import Foundation
import SwiftyJSON

struct WalletTransactionsCellModel {
    let claimID: Int
    let lastUpdated: Int
    let serverTxState: TransactionState
    let dateCreated: Date?
    let id: String
    let to: [WalletTransactionTo]
    
    init(json: JSON) {
        claimID = json["ClaimId"].intValue
        lastUpdated = json["LastUpdated"].intValue
        serverTxState = TransactionState(rawValue: json["ServerTxState"].intValue) ?? .created
        dateCreated = json["DateCreated"].stringValue.dateFromTeambrella
        id = json["Id"].stringValue
        to = json["To"].arrayValue.flatMap { WalletTransactionTo(json: $0) }
    }
}

struct WalletTransactionTo {
    let kind: TransactionKind
    let userID: String
    let name: String
    let amount: Double
    
    init(json: JSON) {
        kind = TransactionKind(rawValue: json["Kind"].intValue) ?? .payout
        userID = json["UserId"].stringValue
        name = json["UserName"].stringValue
        amount = json["Amount"].doubleValue
    }
}
