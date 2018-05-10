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

import UserNotifications
//import UIKit

class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(_ request: UNNotificationRequest,
                             withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        print("content request received")

        guard let content = request.content.mutableCopy() as? UNMutableNotificationContent else { return }
        guard let payloadDict = content.userInfo["Payload"] as? [AnyHashable: Any] else { return }
        guard let apsDict = content.userInfo["aps"] as? [AnyHashable: Any] else { return }

        let aps = APS(dict: apsDict)
        
        let payload = RemotePayload(dict: payloadDict)

        let message = RemoteMessage(aps: aps, payload: payload)
        
        // set content from payload instead of aps
        message.title.flatMap { content.title = $0 }
        message.subtitle.flatMap { content.subtitle = $0 }
        message.body.flatMap { content.body = $0 }

        bestAttemptContent = content

        // remove duplicating messages
        //        UNUserNotificationCenter.current()
        //            .getDeliveredNotifications { notifications in
        //                let matching = notifications.first(where: { notify in
        //                    let threadID = notify.request.content.threadIdentifier
        //                    return threadID == content.threadIdentifier
        //                })
        //                if let matchExists = matching {
        //                    UNUserNotificationCenter.current().removeDeliveredNotifications(
        //                        withIdentifiers: [matchExists.request.identifier]
        //                    )
        //                }
        //        }

        print("fetching attachments for message: \(message)")

        fetchAttachments(message: message) { [weak self] in
            self?.getUpdates {
                if let content = self?.bestAttemptContent {
                    contentHandler(content)
                }
            }
        }
    }

    private func fetchAttachments(message: RemoteMessage, completion: @escaping () -> Void) {
        if let avatarURL = message.avatar {
            UIImage.fetchAvatar(string: avatarURL, completion: { [weak self] image, error in
                if let filePath = self?.saveImage(image: image),
                    let attachment = try? UNNotificationAttachment(identifier: "image", url: filePath, options: nil) {
                    self?.bestAttemptContent?.attachments = [attachment]
                }
                completion()
            })
        } else if let imageURL = message.image {
            UIImage.fetchImage(string: imageURL, completion: { [weak self] image, error in
                if let filePath = self?.saveImage(image: image),
                    let attachment = try? UNNotificationAttachment(identifier: "image", url: filePath, options: nil) {
                    self?.bestAttemptContent?.attachments = [attachment]
                }
                completion()
            })
        } else {
            completion()
        }
    }

    private func getUpdates(completion: @escaping () -> Void) {
        print("getting updates")
        let service = TeambrellaService()
        service.startUpdating { result in
            print("\n\n\nget updates is executed from notifications service\n\n\n")
            completion()
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    func saveImage(image: UIImage?) -> URL? {
        guard let image = image else { return nil }
        
        if let data = UIImagePNGRepresentation(image) {
            let filename = ProcessInfo.processInfo.globallyUniqueString
            let path = URL(fileURLWithPath: NSTemporaryDirectory())
            let filePath = path.appendingPathComponent("\(filename).png")
            do {
                try data.write(to: filePath)
                return filePath
            } catch {
                
            }
        }
        return nil
    }
    
}
