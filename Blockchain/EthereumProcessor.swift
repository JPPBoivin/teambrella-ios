//
//  Ethereum.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 13.09.17.
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
import Geth
import SwiftKeccak

/**
 * Interaction with Ethereum wallet
 */
struct EthereumProcessor {
    enum EthereumProcessorError: Error {
        case noKeyStore
        case noAccount
        case noWIF
        case inconsistentTxData(String)
    }
    
    /// creates a processor with the key that is stored for the current user
    static var standard: EthereumProcessor { return EthereumProcessor(key: service.server.key) }
    
    var key: Key
    
    /// BTC key
    private var secretData: Data { return key.privateKeyData }
    /// BTC WiF
    private var secretString: String { return key.privateKey }
    
    var ethAddressString: String? {
        return ethAddress?.getHex()
    }
    
    var ethKeyStore: GethKeyStore? {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        return GethNewKeyStore(documentsPath + "/keystore" + key.publicKey, GethLightScryptN, GethLightScryptP)
    }
    
    var ethAccount: GethAccount? {
        guard let keyStore = ethKeyStore else { return nil }
        guard let accounts = keyStore.getAccounts() else { return nil }
        
        return accounts.size() == 0
            ? try? keyStore.importECDSAKey(secretData, passphrase: secretString)
            : try? accounts.get(0)
    }
    
    var ethAddress: GethAddress? {
        return ethAccount?.getAddress()
    }
    
    var publicKeySignature: String? {
        guard let signature: Data = sign(publicKey: key.publicKey) else { return nil }
        
        let publicKeySignature = reverseAndCalculateV(data: signature).hexString
        print("Public key signature: \(publicKeySignature)")
        return publicKeySignature
    }
    
    init(key: Key) {
        self.key = key
    }
    
    func sign(publicKey: String) -> Data? {
        // signing last 32 bytes of a string
        guard let keyStore = ethKeyStore else { return nil }
        guard let account = ethAccount else { return nil }
        let data = Data(hex: publicKey)
        
        var bytes: [UInt8] = Array(data)
        guard bytes.count >= 32 else { return nil }
        
        let last32bytes = bytes[(bytes.count - 32)...]
        
        do {
            let storedKeyString = KeyStorage().privateKey
            print(key.debugDescription)
            print("stored private key string: \(storedKeyString)")
            print("ethereum address: \(account.getAddress().getHex())")
            print("last 32 bytes: \(Data(last32bytes).hexString)")
            let signed = try keyStore.signHashPassphrase(account, passphrase: secretString, hash: Data(last32bytes))
            print("signature: \(signed.hexString)")
            return signed
        } catch {
            log("Error signing ethereum: \(error)", type: .error)
            service.error.present(error: error)
            return nil
        }
    }
    
    func reverseAndCalculateV(data: Data) -> Data {
        var bytes: [UInt8] = data.reversed()
        bytes[0] += 27
        return Data(bytes)
    }
    
    // MARK: Transaction
    
    func contractTx(nonce: Int,
                    gasLimit: Int,
                    gasPrice: Int,
                    byteCode: String,
                    arguments: Any...) throws -> GethTransaction {
        let input = try AbiArguments.encodeToHex(arguments)
        let dict = ["nonce": "0x\(nonce)",
            "gasPrice": "0x\(gasPrice)",
            "gas": "0x\(gasLimit)",
            "value": "0x0",
            "input": "0x\(input)",
            "v": "0x29",
            "r": "0x29",
            "s": "0x29"
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
        let json = String(bytes: jsonData, encoding: .utf8) ?? ""
        if let tx = GethTransaction(ref: json) {
            return tx
        } else {
            throw EthereumProcessorError.inconsistentTxData(json)
        }
    }
    
    func depositTx(nonce: Int, gasLimit: Int, toAddress: String, gasPrice: Int, value: Decimal) {
        let weis = value * 1_000_000_000_000_000_000
        let dict = ["nonce": "0x\(nonce)",
            "gasPrice": "0x\(gasPrice)",
            "gasLimit": "0x\(gasLimit)",
            "bytecode": "%"]
    }
    
    func signTx(unsignedTx: GethTransaction, isTestNet: Bool) throws -> GethTransaction {
        guard let keyStore = ethKeyStore else { throw EthereumProcessorError.noKeyStore }
        guard let account = ethAccount else { throw EthereumProcessorError.noAccount }
        
        return try keyStore.signTxPassphrase(account,
                                             passphrase: secretString,
                                             tx: unsignedTx,
                                             chainID: chainID(isTestNet: isTestNet))
    }
    
    func chainID(isTestNet: Bool) -> GethBigInt {
        return GethBigInt(ref: isTestNet ? 3: 1)
    }
    
    /// returns hash made by Keccak algorithm
    func sha3(_ string: String) -> Data {
        return keccak256(string)
    }
    
    /// returns hash made by Keccak algorithm
    func sha3(_ data: Data) -> Data {
        return keccak256(data)
    }
    
}
