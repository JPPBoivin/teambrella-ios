//
//  ExtendedTeammateEntity.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 10.04.17.
//  Copyright © 2017 Yaroslav Pasternak. All rights reserved.
//

import Foundation
import SwiftyJSON

struct ExtendedTeammateEntity: ExtendedTeammate {
    let id: String
    let ver: Int64
    
    let lastUpdated: Int64
    
    var topic: Topic
    let basic: TeammateBasicInfo
    var voting: TeammateVotingInfo?
    let object: CoveredObject
    let stats: TeammateStats
    let riskScale: RiskScaleEntity?

    var description: String {
        return "ExtendedTeammateEntity \(id)"
    }
    
    init(json: JSON) {
        id = json["UserId"].stringValue
        ver = json["Ver"].int64Value
        lastUpdated = json["LastUpdated"].int64Value
        topic = TopicFactory.topic(with: json["DiscussionPart"])
        basic = TeammateBasicInfo(json: json["BasicPart"])
        voting = TeammateVotingInfo(json: json["VotingPart"])
        object = CoveredObject(json: json["ObjectPart"])
        stats = TeammateStats(json: json["StatsPart"])
        riskScale = RiskScaleEntity(json: json["RiskScalePart"])
    }
    
}
