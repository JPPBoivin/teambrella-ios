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

struct RemotePayload {
    struct Claim {
        let id: String
        let userName: String
        let objectName: String
        let avatar: String
        
        init?(dict: [AnyHashable: Any]) {
            var dict = dict
            if let claimDict = dict["Claim"] as? [AnyHashable: Any] { dict = claimDict }
            guard let id = dict["ClaimId"] as? String,
            let userName = dict["UserName"] as? String,
            let objectName = dict["ObjectName"] as? String,
                let avatar = dict["SmallPhoto"] as? String else { return nil }
            
            self.id = id
            self.userName = userName
            self.objectName = objectName
            self.avatar = avatar
        }
    }
    
    struct Teammate {
        let userID: String
        let userName: String
        let avatar: String
        
        init?(dict: [AnyHashable: Any]) {
            var dict = dict
            if let teammateDict = dict["Teammate"] as? [AnyHashable: Any] { dict = teammateDict }
            guard let id = dict["UserId"] as? String,
                let userName = dict["UserName"] as? String,
                let avatar = dict["Avatar"] as? String else { return nil }
            
            self.userID = id
            self.userName = userName
            self.avatar = avatar
        }
    }
    
    struct Discussion {
        let topicName: String
        
        init?(dict: [AnyHashable: Any]) {
            var dict = dict
            if let discussionDict = dict["Discussion"] as? [AnyHashable: Any] { dict = discussionDict }
            guard let topicName = dict["TopicName"] as? String else { return nil }
            
            self.topicName = topicName
        }
    }
    
    let dict: [AnyHashable: Any]
    
    var claim: RemotePayload.Claim?
    var teammate: RemotePayload.Teammate?
    var discussion: RemotePayload.Discussion?
    
    var type: RemoteCommandType { return (dict["Cmd"] as? Int).flatMap { RemoteCommandType(rawValue: $0) } ?? .unknown }
    var timestamp: Int64 { return dict["Timestamp"] as? Int64 ?? 0 }
    
    var teamID: Int? { return dict["TeamId"] as? Int }
    var teamName: String? { return dict["TeamName"] as? String }
    var newTeammatesCount: Int? { return dict["NewTeammates"] as? Int }
    
    var userID: String? { return dict["UserId"] as? String }
    var userName: String? { return dict["UserName"] as? String }
    var teammateID: Int? { return dict["TeammateId"] as? Int }
    var message: String? { return dict["Message"] as? String }
    
    var topicID: String? { return dict["TopicId"] as? String }
    var postID: String? { return dict["PostId"] as? String }
    var topicName: String? { return dict["TopicName"] as? String }
    //var text: String? { return dict["Text"] as? String }
    var postsCount: Int? { return dict["Count"] as? Int }
    
    var claimID: Int? { return dict["ClaimId"] as? Int }
    
    var amount: String? { return dict["Count"] as? String }
    var cryptoAmount: String? { return dict["BalanceCrypto"] as? String }
    var currencyAmount: String? { return dict["BalanceFiat"] as? String }
    
    var avatar: String? { return dict["Avatar"] as? String }
    var teamURL: String? { return dict["TeamUrl"] as? String }
    var teamLogo: String? { return dict["TeamLogo"] as? String }
    
    // MARK: Convenience getters
    
    var teamIDValue: Int { return value(from: teamID) }
    var teamNameValue: String { return value(from: teamName) }
    var newTeammatesCountValue: Int { return value(from: newTeammatesCount) }
    var userIDValue: String { return value(from: userID) }
    var userNameValue: String { return value(from: userName) }
    var teammateIDValue: Int { return value(from: teammateID) }
    var messageValue: String { return value(from: message) }
    var topicIDValue: String { return value(from: topicID) }
    var postIDValue: String { return value(from: postID) }
    var topicNameValue: String { return value(from: topicName) }
    var postsCountValue: Int { return value(from: postsCount) }
    var claimIDValue: Int { return value(from: claimID) }
    var amountValue: String { return value(from: amount) }
    var cryptoAmountValue: String { return value(from: cryptoAmount) }
    var currencyAmountValue: String { return value(from: currencyAmount) }
    
    // get the most relevant image
    var image: String {
        if let avatar = avatar {
            return avatar
        } else if let teamLogo = teamLogo {
            return teamLogo
        }
        return ""
    }
    
    init(dict: [AnyHashable: Any]) {
        self.dict = dict
        self.claim = RemotePayload.Claim(dict: dict)
        self.teammate = RemotePayload.Teammate(dict: dict)
        self.discussion = RemotePayload.Discussion(dict: dict)
    }
    
    private func value(from: String?) -> String {
        return from ?? ""
    }
    
    private func value(from: Int?) -> Int {
        return from ?? 0
    }
    
    private func value(from: Int64?) -> Int64 {
        return from ?? 0
    }
}

struct RemoteMessage {
    let payload: RemotePayload
    
    var title: String? {
        switch payload.type {
        case .createdPost:
            return "New post"
        case .topicMessageNotification:
            return "New message"
        case .newTeammate:
            return "New teammate"
        case .postsSinceInteracted:
            return "You have \(payload.postsCount ?? 0) unread messages"
        case .walletFunded:
            return "Wallet is funded"
        default:
            return nil
        }
    }
    
    var subtitle: String? {
        switch payload.type {
        case .createdPost:
            return nil
        case .topicMessageNotification:
            return payload.userName
        case .newTeammate:
            return payload.userName
        case .walletFunded:
            return "Team: \(payload.teamNameValue)"
        default:
            return nil
        }
    }
    
    var body: String? {
        switch payload.type {
        case .createdPost,
             .privateMessage:
            return payload.message
        case .walletFunded:
            return """
            Wallet for team \(payload.teamNameValue) is funded for \(payload.cryptoAmountValue)mETH \
            (\(payload.currencyAmountValue))
            """
        default:
            return nil
        }
    }
    
    var avatar: String? { return payload.avatar }
    var image: String? { return payload.image }
}

enum RemoteCommandType: Int {
    case unknown = 0
    
    // will come only from Sockets
    case createdPost = 1
    case deletedPost = 2
    case typing = 3
    case newClaim = 4
    
    // may come from Push
    case privateMessage = 5
    case walletFunded = 6
    case postsSinceInteracted = 7
    case newTeammate = 8
    case newDiscussion = 9
    
    case topicMessageNotification = 21
}

enum RemoteCommand {
    case unknown(payload: RemotePayload)
    case createdPost(teamID: Int,
        userID: String,
        topicID: String,
        postID: String,
        name: String,
        avatar: String,
        text: String)
    case deletedPost(teamID: Int,
        userID: String,
        topicID: String,
        postID: String)
    case typing(teamID: Int,
        userID: String,
        topicID: String,
        name: String)
    case newClaim(teamID: Int,
        userID: String,
        claimID: Int,
        name: String,
        avatar: String,
        amount: String,
        teamName: String)
    
    case privateMessage(userID: String,
        name: String,
        avatar: String,
        message: String)
    case walletFunded(teamID: Int,
        userID: String,
        cryptoAmount: String,
        currencyAmount: String,
        teamLogo: String,
        teamName: String)
    case postsSinceInteracted(count: Int)
    case newTeammate(teamID: Int,
        userID: String,
        teammateID: Int,
        name: String,
        avatar: String,
        teamName: String)
    
    case newDiscussion
    case topicMessage
    
    // swiftlint:disable:next function_body_length
    static func command(from payload: RemotePayload) -> RemoteCommand {
        
        switch payload.type {
        case .createdPost:
            return .createdPost(teamID: payload.teamIDValue,
                                userID: payload.userIDValue,
                                topicID: payload.topicIDValue,
                                postID: payload.postIDValue,
                                name: payload.userNameValue,
                                avatar: payload.image,
                                text: payload.messageValue)
        case .deletedPost:
            return .deletedPost(teamID: payload.teamIDValue,
                                userID: payload.userIDValue,
                                topicID: payload.topicIDValue,
                                postID: payload.postIDValue)
        case .typing:
            return .typing(teamID: payload.teamIDValue,
                           userID: payload.userIDValue,
                           topicID: payload.topicIDValue,
                           name: payload.userNameValue)
        case .newClaim:
            return .newClaim(teamID: payload.teamIDValue,
                             userID: payload.userIDValue,
                             claimID: payload.claimIDValue,
                             name: payload.userNameValue,
                             avatar: payload.image,
                             amount: payload.amountValue,
                             teamName: payload.teamNameValue
            )
        case .privateMessage:
            return .privateMessage(userID: payload.userIDValue,
                                   name: payload.userNameValue,
                                   avatar: payload.image,
                                   message: payload.messageValue)
        case .walletFunded:
            return .walletFunded(teamID: payload.teamIDValue,
                                 userID: payload.userIDValue,
                                 cryptoAmount: payload.cryptoAmountValue,
                                 currencyAmount: payload.currencyAmountValue,
                                 teamLogo: payload.image,
                                 teamName: payload.teamNameValue)
        case .postsSinceInteracted:
            return .postsSinceInteracted(count: payload.postsCountValue)
        case .topicMessageNotification:
            return .topicMessage
        case .newTeammate:
            return .newTeammate(teamID: payload.teamIDValue,
                                userID: payload.userIDValue,
                                teammateID: payload.teammateIDValue,
                                name: payload.userNameValue,
                                avatar: payload.image,
                                teamName: payload.teamNameValue)
        default:
            return .unknown(payload: payload)
        }
    }
}
