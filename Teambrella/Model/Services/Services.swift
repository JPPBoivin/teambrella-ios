//
//  Services.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 04.04.17.

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
import PKHUD

fileprivate(set)var service = ServicesHandler.i

class ServicesHandler {
    static let i = ServicesHandler()
    
    let router = MainRouter()
    let reachability: ReachabilityService = ReachabilityService()
    //    lazy var bitcoin = BitcoinService()
    lazy var server = ServerService()
    lazy var teambrella = TeambrellaService()
    lazy var storage: Storage = LocalStorage()
    lazy var push: PushService = PushService()
    lazy var error: ErrorPresenter = ErrorPresenter()
    lazy var log: Log = Log(logLevel: .all)
    lazy var crypto: CryptoUser = CryptoUser()
    lazy var cryptoWorker: CryptoWorker = EthereumWorker()
    
    var socket: SocketService?
    var session: Session?
    
    var currencySymbol: String { return session?.currentTeam?.currencySymbol ?? "" }
    var currencyName: String { return session?.currentTeam?.currency ?? "" }
    
    private init() {
        PKHUD.sharedHUD.gracePeriod = 0.5
    }
    
}
