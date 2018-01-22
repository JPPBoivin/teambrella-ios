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
import Geth

class EthWallet {
    struct Constant {
        static let methodIDteamID = "8d475461"
        static let methodIDcosigners = "22c5ec0f"
        static let methodIDtransfer = "91f34dbd"
        static let txPrefix = "5452"
        static let nsPrefix = "4E53"
        
        static let minGasWalletBalance: Decimal = 0.0075
        static let maxGasWalletBalance: Decimal = 0.01
    }
    
    let processor: EthereumProcessor
    let isTestNet: Bool
    
    lazy var blockchain = { EtherNode(isTestNet: self.isTestNet) }()
    
    // 0.1 Gwei is enough since October 16, 2017 (1 Gwei = 10^9 wei)
    //var gasPrice: Int { return isTestNet ? 11000000001 : 100000001 }
    //var contractGasPrice: Int { return isTestNet ? 11000000001 : 100000001 }
    var gasPrice: Int = -1
    var contractGasPrice: Int = -1
    
    
    var contract: String? {
        guard let fileURL = Bundle.main.path(forResource: "Contract", ofType: "txt") else { return nil }
        
        var string = try? String(contentsOfFile: fileURL, encoding: String.Encoding.utf8)
        if let index = string?.index(of: "\n") {
            string?.remove(at: index)
        }
        return string
    }
    
    init(isTestNet: Bool, processor: EthereumProcessor) {
        self.isTestNet = isTestNet
        self.processor = processor
    }
    
    enum EthWalletError: Error {
        case multisigHasNoCosigners(Int)
        case contractDoesNotExist
        case multisigHasNoCreationTx(Int)
        case allGasUsed
    }
    
    func createOneWallet(myNonce: Int,
                         multisig: Multisig,
                         gaslLimit: Int,
                         gasPrice: Int,
                         completion: @escaping (String) -> Void,
                         failure: @escaping (Error?) -> Void) {
        let cosigners = multisig.cosigners
        guard !cosigners.isEmpty else {
            log("Multisig address id: \(multisig.id) has no cosigners", type: [.error, .crypto])
            failure(EthWalletError.multisigHasNoCosigners(multisig.id))
            return
        }
        //        guard let creationTx = multisig.creationTx else {
        //            failure(EthWalletError.multisigHasNoCreationTx(multisig.id))
        //            return
        //        }
        
        let addresses = cosigners.flatMap { $0.teammate.address }
        guard let contract = contract else {
            failure(EthWalletError.contractDoesNotExist)
            return
        }
        
        do {
            var cryptoTx = try processor.contractTx(nonce: myNonce,
                                                    gasLimit: gaslLimit,
                                                    gasPrice: gasPrice,
                                                    byteCode: contract,
                                                    arguments: [addresses, multisig.teamID])
            cryptoTx = try processor.signTx(unsignedTx: cryptoTx, isTestNet: isTestNet)
            log("CryptoTx created teamID: \(multisig.teamID), tx: \(cryptoTx)", type: .crypto)
            publish(cryptoTx: cryptoTx, completion: completion, failure: failure)
        } catch let AbiArguments.AbiArgumentsError.unEncodableArgument(wrongArgument) {
            print("AbiArguments failed to accept the wrong argument: \(wrongArgument)")
        } catch {
            failure(error)
        }
    }
    
    func publish(cryptoTx: GethTransaction,
                 completion: @escaping (String) -> Void,
                 failure: @escaping (Error?) -> Void) {
        do {
            let rlp = try cryptoTx.encodeRLP()
            let hex = "0x" + Hex().hexStringFrom(data: rlp)
            blockchain.pushTx(hex: hex, success: { string in
                completion(string)
            }, failure: { error in
                failure(error)
            })
        } catch {
            failure(error)
        }
    }
    
    func checkMyNonce(success: @escaping (Int) -> Void, failure: @escaping (Error?) -> Void) {
        guard let address = processor.ethAddressString else { return }
        
        blockchain.checkNonce(addressHex: address, success: { nonce in
            print("Nonce: \(nonce)")
            success(nonce)
        }) { error in
            failure(error)
        }
    }
    
    /**
     * Verfifies if a given contract creation TX has been mined in the blockchain.
     *
     * - Parameter gasLimit: original gas limit, that has been set to the original creation TX.
     *  When a TX consumes all the gas up to the limit, that indicates an error.
     *  - Parameter multisig: the given multisig object with original TX hash to check.
     * - returns: original multisig object with updated address (when verified successfully), updated error status
     * (if any), or new unconfirmed tx if original TX is outdated.
     */
    func validateCreationTx(multisig: Multisig,
                            gasLimit: Int,
                            success: @escaping (String) -> Void,
                            notmined: @escaping (Int) -> Void,
                            failure: @escaping (Error?) -> Void) {
        guard let creationTx = multisig.creationTx else {
            failure(EthWalletError.multisigHasNoCreationTx(multisig.id))
            return
        }
        
        //let blockchain = EtherNode(isTestNet: isTestNet)
        blockchain.checkTx(creationTx: creationTx, success: { txReceipt in
            if !txReceipt.blockNumber.isEmpty {
                let gasUsed = Int(hexString: txReceipt.gasUsed)
                let isAllGasUsed = gasUsed == gasLimit
                if !isAllGasUsed {
                    success(txReceipt.contractAddress)
                } else {
                    failure(EthWalletError.allGasUsed)
                }
            } else {
                notmined(gasLimit)
            }
        }, failure: { error in
            failure(error)
        })
    }

    func refreshGasPrice(completion: @escaping (Int) -> Void) {
        let gasStation = GasStation()
        gasStation.gasPrice { [weak self] price, error in
            guard let `self` = self else { return }

            if let error = error {
                print("refresh gas error: \(error)")
            }

            switch price {
            case ..<0:
                print("Failed to get the gas price from a server. A default gas price will be used.")
                self.gasPrice = 100_000_001
            case 50_000_000_001...:
                print("The server is kidding with us about the gas price: \(price)")
                self.gasPrice = 50_000_000_001
            default:
                self.gasPrice = price
            }
            completion(self.gasPrice)
        }
    }

    func refreshContractCreationGasPrice(completion: @escaping (Int) -> Void) {
        let gasStation = GasStation()
        gasStation.contractCreationGasPrice { [weak self] price, error in
            guard let `self` = self else { return }

            if let error = error {
                print("refresh gas error: \(error)")
            }

            switch price {
            case ..<0:
                print("Failed to get the gas price from a server. A default gas price will be used.")
                self.contractGasPrice = 100_000_001
            case 8_000_000_002...:
                print("The server is kidding with us about the contract gas price: \(price)")
                self.contractGasPrice = 8_000_000_001
            default:
                self.contractGasPrice = price
            }
            completion(self.contractGasPrice)
        }
    }

    func deposit(multisig: Multisig, completion: @escaping (Bool) -> Void) {
        guard let address = processor.ethAddressString else { return }
        
        blockchain.checkBalance(address: address, success: { gasWalletAmount in
            print("balance is \(gasWalletAmount)")
            if gasWalletAmount > Constant.maxGasWalletBalance {
                self.refreshGasPrice(completion: { gasPrice in
                    self.blockchain.checkNonce(addressHex: address, success: { nonce in
                        let value = gasWalletAmount - Constant.minGasWalletBalance
                        do {
                            var tx = try self.processor.depositTx(nonce: nonce,
                                                                  gasLimit: 50000,
                                                                  toAddress: multisig.address!,
                                                                  gasPrice: gasPrice,
                                                                  value: value)
                            try tx = self.processor.signTx(unsignedTx: tx, isTestNet: self.isTestNet)
                            self.publish(cryptoTx: tx, completion: { txHash in
                                print("Deposit tx published: \(txHash)")
                                completion(true)
                            }, failure: { error in
                                print("Publish Tx failed with \(String(describing: error))")
                                completion(false)
                            })
                        } catch {
                            print("Deposit Tx creation failed with \(String(describing: error))")
                            completion(false)
                        }
                    }, failure: { error in
                        print("Check nonce failed with \(String(describing: error))")
                        completion(false)
                    })
                })
            }
        }, failure: { error in
            print("Check balance failed with \(String(describing: error))")
            completion(false)
        })
    }

    func cosign(transaction: Tx, payOrMoveFrom: TxInput) -> Data {
        guard let kind = transaction.kind else {
            fatalError()
        }

        switch kind {
        case .moveToNextWallet:
            return cosignMove(transaction: transaction, moveFrom: payOrMoveFrom)
        default:
            return cosignPay(transaction: transaction, payFrom: payOrMoveFrom)
        }
    }

    // MARK: TODO
    func cosignPay(transaction: Tx, payFrom: TxInput) -> Data {
        return Data()
    }

    func cosignMove(transaction: Tx, moveFrom: TxInput) -> Data {
        return Data()
    }
    
}
