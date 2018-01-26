//
//  SocketData.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 11.09.17.
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

enum SocketData {
    case auth
    case newPost(teamID: Int,
        userID: String,
        topicID: String,
        postID: String,
        name: String,
        url: String,
        text: String)
    case deletePost(teamID: Int,
        userID: String,
        topicID: String,
        postID: String)
    case meTyping(teamID: Int,
        topicID: String,
        name: String)
    case newClaim(teamID: Int,
        userID: String,
        claimID: String,
        name: String,
        url: String,
        amount: Double,
        teamURL: String,
        teamName: String)
    case privateMessage(userID: String,
        name: String,
        url: String,
        text: String)
    case walletFunded(teamID: Int,
        userID: String,
        newAmount: Double,
        fiatAmount: String,
        teamURL: String,
        teamName: String)
    case newMessages(count: Int)
    case theyTyping(teamID: Int,
        userID: String,
        topicID: String,
        name: String)
    case dbDump(timestamp: Int64)
    
    var stringValue: String {
        var strings: [String] = [String(command.rawValue)]
        switch self {
        case .auth:
            break
        default:
            let mirror = Mirror(reflecting: self)
            if let child = mirror.children.first {
                let tuple = Mirror(reflecting: child.value)
                for item in tuple.children {
                    strings.append("\(item.value)")
                }
            }
        }
        return strings.joined(separator: ";")
    }
    
    var command: SocketCommand {
        switch self {
        case .auth:
            return .auth
        case .newPost(teamID: _, userID: _, topicID: _, postID: _, name: _, url: _, text: _):
            return .newPost
        case .deletePost(teamID: _, userID: _, topicID: _, postID: _):
            return .deletePost
        case .meTyping(teamID: _, topicID: _, name: _):
            return .meTyping
        case .newClaim(teamID: _, userID: _, claimID: _, name: _, url: _, amount: _, teamURL: _, teamName: _):
            return .newClaim
        case .privateMessage(userID: _, name: _, url: _, text: _):
            return .privateMessage
        case .walletFunded(teamID: _, userID: _, newAmount: _, fiatAmount: _, teamURL: _, teamName: _):
            return .walletFunded
        case .newMessages(count: _):
            return .newMessages
        case .theyTyping(teamID: _, userID: _, topicID: _, name: _):
            return .theyTyping
        case .dbDump(timestamp: _):
            return .dbDump
        }
    }
    
    static func with(command: SocketCommand, json: JSON) -> SocketData? {
        switch command {
        case .auth:
            return .auth
        case .newPost:
            /*{"Cmd":1,
             "Timestamp":636498845894664979,
             "UserId":"dc11507d-d8c5-46ff-81ae-a7c300795fda",
             "TeamId":2001,"TopicId":"fd6bcdc7-2b79-4525-af77-a85001161d49",
             "PostId":"073e2a28-f028-4e0b-8ec9-3bf26e30cf1b",
             "UserName":"Denis Vasilin",
             "Avatar":"/content/uploads/dc11507d-d8c5-46ff-81ae-a7c300795fda/
             197da98c-e958-45ad-990c-a7c300796106_fb.jpg?width=128&crop=0,0,128,128",
             "Content":"🍺"}*/
            return .newPost(teamID: json["TeamId"].intValue,
                            userID: json["UserId"].stringValue,
                            topicID: json["TopicId"].stringValue,
                            postID: json["PostId"].stringValue,
                            name: json["UserName"].stringValue,
                            url: json["Avatar"].stringValue,
                            text: json["Content"].stringValue)
        case .theyTyping:
            /*
             {"Cmd":13,
             "Timestamp":636500607291514776,
             "UserId":"9c4a1984-66f9-4f3c-8470-a7c3006c9400",
             "TeamId":2021,
             "TopicId":"21f43e0e-a599-4e5f-8f4f-a6d7ff0195c1",
             "UserName":"Vlad Kravchuk"}
             */
            return .theyTyping(teamID: json["TeamId"].intValue,
                               userID: json["UserId"].stringValue,
                               topicID: json["TopicId"].stringValue,
                               name: json["UserName"].stringValue)
        case .dbDump:
            return .dbDump(timestamp: json["Timestamp"].int64Value)
        default:
            return nil
        }
    }
    
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    static func with(command: SocketCommand, components: [String]) -> SocketData? {
        switch command {
        case .auth:
            return .auth
        case .newPost:
            if components.count > 7,
                let teamID = Int(components[1]) {
                return .newPost(teamID: teamID,
                                userID: components[2],
                                topicID: components[3],
                                postID: components[4],
                                name: components[5],
                                url: components[6],
                                text: components[7])
            }
        case .deletePost:
            if components.count > 4, let teamID = Int(components[1]) {
                return .deletePost(teamID: teamID, userID: components[2], topicID: components[3], postID: components[4])
            }
        case .meTyping:
            if components.count > 3, let teamID = Int(components[1]) {
                return .meTyping(teamID: teamID, topicID: components[2], name: components[3])
            }
        case .newClaim:
            if components.count > 8,
                let teamID = Int(components[1]),
                let amount = Double(components[6]) {
                return .newClaim(teamID: teamID,
                                 userID: components[2],
                                 claimID: components[3],
                                 name: components[4],
                                 url: components[6],
                                 amount: amount,
                                 teamURL: components[7],
                                 teamName: components[8])
            }
        case .privateMessage:
            if components.count > 4 {
                return .privateMessage(userID: components[1],
                                       name: components[2],
                                       url: components[3],
                                       text: components[4])
            }
        case .walletFunded:
            if components.count > 6, let teamID = Int(components[1]), let newAmount = Double(components[3]) {
                return .walletFunded(teamID: teamID,
                                     userID: components[2],
                                     newAmount: newAmount,
                                     fiatAmount: components[4],
                                     teamURL: components[5],
                                     teamName: components[6])
            }
        case .newMessages:
            if components.count > 1, let count = Int(components[1]) {
                return .newMessages(count: count)
            }
        case .theyTyping:
            if components.count > 4, let teamID = Int(components[1]) {
                return .theyTyping(teamID: teamID,
                                   userID: components[2],
                                   topicID: components[3],
                                   name: components[4])
            }
        case .newTeammate:
            // 8;<teamId>;<userId>;<teammateId>;<name>;<url>;<teamurl>;<teamname>
            break
        case .newTeammates:
            // 9;<teamId>;<qty>;<teamurl>;<teamname>
            break
        case .dbDump:
            break
        }
        return nil
    }
    
}
