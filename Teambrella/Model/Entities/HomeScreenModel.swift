//
//  HomeScreenModel.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 06.07.17.
//  Copyright © 2017 Yaroslav Pasternak. All rights reserved.
//

import Foundation
import SwiftyJSON

struct HomeScreenModel {
    enum ItemType: Int {
        case teammate = 0
        case claim = 1
        case rule = 2
        case teamChat = 3
        case teamNotification = 100
    }
    
    struct Card {
        let json: JSON
        
        var itemType: ItemType { return ItemType(rawValue: json["ItemType"].intValue) ?? .teammate }
        var itemId: Int { return json["ItemId"].intValue }
        var itemDate: Date? { return json["ItemDate"].stringValue.dateFromISO8601 }
        var smallPhoto: String { return json["SmallPhotoOrAvatar"].stringValue }
        var amount: Double { return json["Amount"].doubleValue }
        var teamVote: Double { return json["TeamVote"].doubleValue }
        var isVoting: Bool { return json["IsVoting"].boolValue }
        var text: String { return json["Text"].stringValue }
        var unreadCount: Int { return json["UnreadCount"].intValue }
    }
    
    let json: JSON
    var cards: [Card]
    
    var userID: String { return json["UserId"].stringValue }
    var name: String { return json["Name"].stringValue }
    var avatar: String { return json["Avatar"].stringValue }
    var unreadCount: Int { return json["UnreadCount"].intValue }
    var currency: String { return json["Currency"].stringValue }
    var balance: Double { return json["BtcBalance"].doubleValue }
    var coverage: Double { return json["Coverage"].doubleValue }
    var objectName: String { return json["ObjectName"].stringValue }
    var smallPhoto: String { return json["SmallPhoto"].stringValue }
    var coverageType: Int { return json["CoverageType"].intValue } //
    var haveVotingClaims: Bool { return json["HaveVotingClaims"].boolValue }
    
    init(json: JSON) {
        self.json = json
        cards = json["Cards"].arrayValue.flatMap { Card(json: $0) }
    }
}
