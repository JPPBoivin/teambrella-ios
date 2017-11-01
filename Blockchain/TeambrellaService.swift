//
//  TeambrellaService.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 11.05.17.

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
import SwiftyJSON

protocol TeambrellaServiceDelegate: class {
    func teambrellaDidUpdate(service: TeambrellaService)
}

class TeambrellaService {
    struct Constant {
        static let maxAttempts = 3
        static let gasLimit = 1300000
    }
    
    let queue = DispatchQueue(label: "com.teambrella.ethereumWorker.queue", qos: .background)
    var hasNews: Bool = false
    
    let server = BlockchainServer()
    let contentProvider: TeambrellaContentProvider = TeambrellaContentProvider()
    
    lazy var processor: EthereumProcessor = { EthereumProcessor.standard }()
    
    weak var delegate: TeambrellaServiceDelegate?
    
    var key: Key { return Key(base58String: self.contentProvider.user.privateKey, timestamp: self.server.timestamp) }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func startUpdating() {
        update()
    }
    
    private func update() {
        log("Teambrella service begins updates", type: .crypto)
        let blockchain = BlockchainService(contentProvider: contentProvider, server: server)
        updateData { success in
            if success {
                blockchain.updateData()
                self.contentProvider.save()
                self.delegate?.teambrellaDidUpdate(service: self)
            }
        }
        
    }
    
    func clear() throws {
        try contentProvider.clear()
    }
    
    func updateData(completion: @escaping (Bool) -> Void) {
        server.initClient(privateKey: contentProvider.user.privateKey) { [unowned self] success in
            if success {
                self.autoApproveTransactions()
                self.serverUpdateToLocalDb { success in
                    if success {
                        
//                        self.updateAddresses()
                        completion(true)
                    } else {
                        completion(false)
                    }
                }
            } else {
                completion(false)
            }
        }
    }
    
    func serverUpdateToLocalDb(completion: @escaping (Bool) -> Void) {
        let txsToUpdate = contentProvider.transactionsNeedServerUpdate
        let signatures = contentProvider.signaturesToUpdate
        let user = contentProvider.user
        server.getUpdates(privateKey: user.privateKey,
                          lastUpdated: user.lastUpdated,
                          transactions: txsToUpdate,
                          signatures: signatures) { [unowned self] reply in
                            switch reply {
                            case .success(let json, let timestamp):
                                log("BlockchainStorage Server update to local db received json: \(json)", type: .crypto)
                                let factory = EntityFactory(fetcher: self.contentProvider)
                                factory.updateLocalDb(txs: txsToUpdate, signatures: signatures, json: json)
                                user.lastUpdated = timestamp
                                self.contentProvider.save()
                                completion(true)
                                break
                            case .failure(let error):
                                print("server request failed with error: \(error)")
                                completion(false)
                            }
        }
    }
    
    func autoApproveTransactions() {
        let txs = contentProvider.transactionsResolvable
        for tx in txs {
            let daysLeft = contentProvider.daysToApproval(tx: tx, isMyTx: contentProvider.isMy(tx: tx))
            if daysLeft <= 0 {
                tx.resolution = .approved
                tx.isServerUpdateNeeded = true
            }
        }
        contentProvider.save()
    }
    
    /*
    private func updateAddresses() {
        for teammate in contentProvider.teammates {
            guard teammate.addresses.isEmpty == false else { continue }
            
            if teammate.addressCurrent == nil {
                let filtered = teammate.addresses.filter { $0.status == UserAddressStatus.current }
                if let curServerAddress = filtered.first {
                    curServerAddress.status = .current
                }
            }
        }
    }
    */
    
    //    private var observerToken: NSKeyValueObservation?
    
//    init() {
//        observerToken = service.server.observe(\.timestamp) { [weak self] object, change in
//            self?.processor.key = object.key
//        }
//    }
    
    func sync() {
        self.queue.async { [unowned self] in
            var attemptsLeft = Constant.maxAttempts
            while attemptsLeft > 0 && self.hasNews {
                self.createWallets(gasLimit: Constant.gasLimit)
                self.verifyIfWalletIsCreated()
                self.depositWallet()
                self.autoApproveTxs()
                self.cosignApprovedTransactions()
                self.masterSign()
                self.publishApprovedAndCosignedTxs()
                self.update()
//                self.hasNews =
                attemptsLeft -= 1
            }
        }
    }
    
    @discardableResult
    func createWallets(gasLimit: Int) -> Bool {
        let myPublicKey = key.publicKey
        let multisigsToCreate = contentProvider.multisigsToCreate(publicKey: myPublicKey)
        guard !multisigsToCreate.isEmpty else { return false }
        
        let wallet = EthWallet(isTestNet: false, processor: processor)
        
        //processor.
        // WIP!
        return false
    }
    
    func verifyIfWalletIsCreated() {
        
    }
    
    func depositWallet() {
        
    }
    
    func autoApproveTxs() {
        
    }
    
    func cosignApprovedTransactions() {
        
    }
    
    func masterSign() {
        
    }
    
    func publishApprovedAndCosignedTxs() {
        
    }
    
//    func update() -> Bool {
//        return false
//    }
    
}

// Helpers

extension TeambrellaService {
    func approve(tx: Tx) {
        contentProvider.transactionsChangeResolution(txs: [tx], to: .approved)
        self.delegate?.teambrellaDidUpdate(service: self)
        //update()
    }
}
