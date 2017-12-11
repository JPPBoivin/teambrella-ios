//
/* Copyright(C) 2017 Teambrella, Inc.
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

protocol BasicPart {
    var userID: String { get }
    var name: String { get }
    var avatar: String { get }
    var model: String { get }
    var year: Int { get }
    var smallPhoto: String { get }
    
    init(json: JSON)
}

struct BasicPartTeammateConcrete: BasicPart {
    let userID: String
    let name: String
    let avatar: String
    let model: String
    let year: Int
    let smallPhoto: String
    
    init(json: JSON) {
        userID = json["UserId"].stringValue
        name = json["Name"].stringValue
        avatar = json["Avatar"].stringValue
        model = json["Model"].stringValue
        year = json["Year"].intValue
        smallPhoto = json["SmallPhoto"].stringValue
    }
}

struct BasicPartClaimConcrete: BasicPart {
    let userID: String
    let name: String
    let avatar: String
    let model: String
    let year: Int
    var smallPhoto: String { return smallPhotos.first ?? "" }
    
    let deductible: Double
    let bigPhotos: [String]
    let smallPhotos: [String]
    let coverage: Double
    let claimAmount: Double
    let estimatedExpenses: Double
    let incidentDate: Date?
    
    init(json: JSON) {
        userID = json["UserId"].stringValue
        name = json["Name"].stringValue
        avatar = json["Avatar"].stringValue
        model = json["Model"].stringValue
        year = json["Year"].intValue
        
        deductible = json["Deductible"].doubleValue
        bigPhotos = json["BigPhotos"].arrayObject as? [String] ?? []
        smallPhotos = json["BigPhotos"].arrayObject as? [String] ?? []
        coverage = json["Coverage"].doubleValue
        claimAmount = json["ClaimAmount"].doubleValue
        estimatedExpenses = json["EstimatedExpenses"].doubleValue
        incidentDate = Formatter.teambrella.date(from: json["IncidentDate"].stringValue)
    }
    
}

struct BasicPartFactory {
    static func basicPart(from json: JSON) -> BasicPart? {
        var json = json
        if json["BasicPart"].exists() { json = json["BasicPart"] }
        
        if json["ClaimAmount"].exists() {
            return BasicPartClaimConcrete(json: json)
        } else if json["UserId"].exists() {
            return BasicPartTeammateConcrete(json: json)
        } else {
            return nil
        }
    }
    
}
