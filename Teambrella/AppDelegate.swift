//
//  AppDelegate.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 28.03.17.

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

import UIKit
//import FacebookLogin
import FBSDKCoreKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)

        // Register for Push here to be able to receive silent notifications even if user will restrict push service
        application.registerForRemoteNotifications()
        TeambrellaStyle.apply()
        if let notification = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            service.push.remoteNotificationOnStart(in: application, userInfo: notification)
        }
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)

        // Pull in case of emergency :)
        // service.cryptoMalfunction()

        configureLibs()

        return true
    }
    
    func application(_ application: UIApplication,
                     open url: URL,
                     sourceApplication: String?,
                     annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application,
                                                                     open: url,
                                                                     sourceApplication: sourceApplication,
                                                                     annotation: annotation)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        service.socket?.start()

        if service.session != nil {
            service.teambrella.startUpdating(completion: { result in
                let description = result.rawValue == 0 ? "new data" : result.rawValue == 1 ? "no data" : "failed"
                log("Teambrella service get updates results: \(description)", type: .info)
            })
        }

        service.info.prepareServices()
        let router = service.router
        let info = service.info
        SODManager(router: router).checkSilentPush(infoMaker: info)

        stitches()
    }

    /// move all users to real group once
    private func stitches() {
        let storage = SimpleStorage()
        if let lastUserType = storage.string(forKey: .lastUserType),
            lastUserType == KeyStorage.LastUserType.real.rawValue {
            return
        }

        if storage.bool(forKey: .didMoveToRealGroup) == false {
            service.router.logout()
            service.keyStorage.setToRealUser()
            storage.store(bool: false, forKey: .didLogWithKey)
            storage.store(bool: true, forKey: .didMoveToRealGroup)
        }
    }

    private func configureLibs() {
        // Add firebase support
        FirebaseApp.configure()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        service.socket?.stop()
    }
    
    // MARK: Push
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        service.push.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        service.push.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        log("remote notification: \(userInfo)", type: .push)
        service.push.remoteNotification(in: application, userInfo: userInfo, completionHandler: completionHandler)
    }

    func application(_ application: UIApplication,
                     performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        service.teambrella.startUpdating(completion: completionHandler)

    }
    
}
