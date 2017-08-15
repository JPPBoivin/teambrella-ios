//
//  ClaimEntity.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 02.06.17.

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

import Foundation
import SwiftyJSON

struct ClaimEntity: ClaimLike {
    var id: String
    var lastUpdated: Int64
    
    var smallPhoto: String
    var avatar: String
    var model: String
    var name: String
    var state: ClaimState
    var claimAmount: Double
    var reimbursement: Double
    var votingResBTC: Double
    var paymentResBTC: Double
    
    var proxyAvatar: String?
    var proxyName: String?
    
    var description: String {
        return "\(#file) \(id)"
    }
    
    init(json: JSON) {
        id = json["Id"].stringValue
        lastUpdated = json["LastUpdated"].int64Value
        smallPhoto = json["SmallPhoto"].stringValue
        avatar = json["Avatar"].stringValue
        model = json["Model"].stringValue
        name = json["Name"].stringValue
        state = ClaimState(rawValue: json["State"].intValue) ?? .voting
        claimAmount = json["ClaimAmount"].doubleValue
        reimbursement = json["Reimbursement"].doubleValue
        votingResBTC = json["VotingRes_BTC"].doubleValue
        paymentResBTC = json["PaymentRes_BTC"].doubleValue
        proxyAvatar = json["ProxyAvatar"].string
        proxyName = json["ProxyName"].string
    }
}

struct ClaimFactory {
    static func claim(with json: JSON) -> ClaimLike {
        return ClaimEntity(json: json)
    }
    
    static func claims(with json: JSON) -> [ClaimLike] {
        return json.arrayValue.map { self.claim(with: $0) }
    }
}
