//
//  PushService.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 31.08.17.
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

import UIKit
import UserNotifications

class PushService: NSObject {
    var token: Data?
    var tokenString: String? {
        guard let token = token else { return nil }
        
        return [UInt8](token).reduce("") { $0 + String(format: "%02x", $1) }
    }
    var command: RemotePayload?
    var router: MainRouter { return service.router }
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func askPermissionsForRemoteNotifications(application: UIApplication) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                // moved token register to AppDelegate
                //application.registerForRemoteNotifications()
                if !granted {
                    log("User Notification permission denied: \(String(describing: error))", type: [.error, .push])
                    //service.error.present(error: error)
                }
            }
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        token = deviceToken
        log("Did register for remote notifications with token \(tokenString ?? "nil")", type: .push)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        log("Failed to register for remote notifications: \(error)", type: [.error, .push])
        service.error.present(error: error)
    }
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            log("Notification settings: \(settings)", type: [.push, .info])
        }
    }
    
    func remoteNotificationOnStart(in application: UIApplication,
                                   userInfo: [AnyHashable: Any]) {
      prepareCommand(userInfo: userInfo)
    }
    
    func remoteNotification(in application: UIApplication,
                            userInfo: [AnyHashable: Any],
                            completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let aps = userInfo["aps"] as? [AnyHashable: Any], let content = aps["content-available"] as? Bool {
            if content == true {
                log("Content is available: \(userInfo)", type: .push)
                service.teambrella.startUpdating(completion: { result in
                    log("Remote notification get updetes result is: \(result)", type: .push)
                })
            }
        }
        guard command == nil else { return }

        prepareCommand(userInfo: userInfo)
        executeCommand()
    }

    private func prepareCommand(userInfo: [AnyHashable: Any]) {
        guard let payloadDict = userInfo["Payload"] as? [AnyHashable: Any] else { return }
        guard let apsDict = userInfo["aps"] as? [AnyHashable: Any] else { return }

        log("\(userInfo)", type: .push)
        let aps = APS(dict: apsDict)
        let payload = RemotePayload(dict: payloadDict)
        self.command = payload

        clearNotificationsThread(id: aps.threadID)
    }
    
    func executeCommand() {
        guard let command = command else { return }
        
        let type = command.type
        switch type {
        case .newTeammate:
            router.presentMemberProfile(teammateID: String(command.teammateIDValue))
        case .privateMessage:
             showPrivateMessage(command: command)
        case .walletFunded:
            showWalletFunded(teamID: command.teamIDValue)
        case .topicMessage:
            showTopic(details: command.topicDetails)
        case .newClaim:
             showNewClaim(teamID: command.teamIDValue, claimID: command.claimIDValue)
        default:
            break
        }
        self.command = nil
    }

    private func clearNotificationsThread(id: String?) {
        guard let id = id else { return }

        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            let ids: [String] = notifications.compactMap { notification in
                if notification.request.content.threadIdentifier == id {
                    return notification.request.identifier
                } else {
                    return nil
                }
            }
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ids)
        }
    }
    
    private func showNewClaim(teamID: Int, claimID: Int) {
        if selectCorrectTeam(teamID: teamID) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
               // service.router.switchTeam()
//                service.router.presentClaims(animated: false)
            service.router.presentClaim(claimID: claimID)
            }
        }
    }
    
    private func showPrivateMessage(command: RemotePayload) {
        service.router.presentPrivateMessages()
        if let user = PrivateChatUser(remotePayload: command) {
            let context = ChatContext.privateChat(user)
            service.router.presentChat(context: context, itemType: .privateChat, animated: false)
        }
    }
    
    private func selectCorrectTeam(teamID: Int) -> Bool {
        if let session = service.session {
            if let team = session.currentTeam, team.teamID != teamID {
                for team in session.teams where team.teamID == teamID {
                    service.session?.switchToTeam(id: teamID)
                    service.router.switchTeam()
                    return true
                }
            } else {
                return true
            }
        }
        return false
    }
    
    private func showWalletFunded(teamID: Int) {
        if selectCorrectTeam(teamID: teamID) {
            service.router.switchToWallet()
        }
    }
    
    private func showTopic(details: RemoteTopicDetails?) {
        if let details = details as? RemotePayload.Claim {
            service.router.switchToFeed()
            service.router.presentClaims(animated: false)
            service.router.presentClaim(claimID: details.claimID, animated: false)
            service.router.presentChat(context: ChatContext.remote(details), itemType: .claim, animated: false)
        } else if let details = details as? RemotePayload.Discussion {
            service.router.presentChat(context: ChatContext.remote(details), itemType: .teamChat, animated: false)
        } else if let details = details as? RemotePayload.Teammate {
            service.router.presentMemberProfile(teammateID: details.userID, animated: false)
            service.router.presentChat(context: ChatContext.remote(details), itemType: .teammate, animated: false)
        }
    }
    
}

extension PushService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler:
        @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound, .badge])
    }
}
