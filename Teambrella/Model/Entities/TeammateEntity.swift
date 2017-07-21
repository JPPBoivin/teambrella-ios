//
//  TeammateEntity.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 05.04.17.
//  Copyright © 2017 Yaroslav Pasternak. All rights reserved.
//

import Foundation
import SwiftyJSON

struct TeammateEntity: TeammateLike {
    var lastUpdated: Int64
    let id: String

    let claimLimit: Int
    let claimsCount: Int
    let isJoining: Bool
    let isVoting: Bool
    let model: String
    let name: String
    let risk: Double
    let riskVoted: Double
    let totallyPaid: Double
    let hasUnread: Bool
    let userID: String
    let year: Int
    let avatar: String
    
    var extended: ExtendedTeammate?
        
    var description: String {
        return "Teammate \(name) id: \(id); ver: \(lastUpdated)"
    }
    
    var isComplete: Bool { return extended != nil }

    init(json: JSON) {
        claimLimit = json["ClaimLimit"].intValue
        claimsCount = json["ClaimsCount"].intValue
        id = json["Id"].stringValue
        isJoining = json["IsJoining"].boolValue
        isVoting = json["IsVoting"].boolValue
        model = json["Model"].stringValue
        name = json["Name"].stringValue
        risk = json["Risk"].doubleValue
        riskVoted = json["RiskVoted"].doubleValue
        totallyPaid = json["TotallyPaid"].doubleValue
        hasUnread = json["Unread"].boolValue
        userID = json["UserId"].stringValue
        lastUpdated = json["LastUpdated"].int64Value
        year = json["Year"].intValue
        avatar = json["Avatar"].stringValue
    }
    
    mutating func updateWithVote(json: JSON) {
        extended?.voting = TeammateVotingInfo(json: json["VotingPart"])
        extended?.topic.minutesSinceLastPost = json["DiscussionPart"]["SinceLastPostMinutes"].intValue
        extended?.topic.unreadCount = json["DiscussionPart"]["UnreadCount"].intValue
    }
    
}

struct TeammateEntityFactory {
    static func teammates(from json: JSON) -> [TeammateEntity]? {
        guard let teammates = json["Teammates"].array else { return nil }
        
        return teammates.map { TeammateEntity(json: $0) }
    }
    
    static func extendedTeammate(from json: JSON) -> ExtendedTeammateEntity? {
        return ExtendedTeammateEntity(json: json)
    }
}
