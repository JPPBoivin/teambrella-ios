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
import SwiftyJSON

class EtherNode {
    struct Constant {
        static let testAuthorities: [String] = ["https://ropsten.etherscan.io/"]
        static let mainAuthorities: [String] = ["http://api.etherscan.io/"]
    }
    
    enum EtherNodeError: Error {
        case malformedJSON(JSON)
    }
    
    private var ethereumAPIs: [EtherAPI] = []
    private var isTestNet: Bool
    
    init(isTestNet: Bool) {
        self.isTestNet = isTestNet
        
        let authorities = isTestNet ? Constant.testAuthorities : Constant.mainAuthorities
        for authority in authorities {
            let api = EtherAPI(server: authority)
            ethereumAPIs.append(api)
        }
    }
    
    func pushTx(hex: String, success: @escaping (String) -> Void, failure: @escaping (Error?) -> Void) {
        let group = DispatchGroup()
        var isSuccessful = false
        var lastError: Error?
        for api in ethereumAPIs {
            group.enter()
            api.pushTx(hex: hex).observe { result in
                switch result {
                case let .value(string):
                    success(string)
                    isSuccessful = true
                case let .error(error):
                    lastError = error
                default:
                    break
                }
                group.leave()
            }
            group.wait()
            if isSuccessful {
                break
            }
        }
        failure(lastError)
        
    }
    
    func checkNonce(addressHex: String, success: @escaping (Int) -> Void, failure: @escaping (Error?) -> Void) {
        guard let api = ethereumAPIs.first else { return }
        
        api.checkNonce(address: addressHex, success: { json in
            guard let string = json.string,
                let nonce = Int(hexString: string) else {
                    failure(EtherNodeError.malformedJSON(json))
                    return
            }
            
            success(nonce)
        }, failure: { error in
            failure(error)
        })
    }
    
    func checkTx(creationTx: String, success: @escaping (TxReceipt) -> Void, failure: @escaping (Error?) -> Void) {
        guard let api = ethereumAPIs.first else { return }
        
        api.checkTx(hash: creationTx, success: { json in
            guard let txReceipt = TxReceipt(json: json) else {
                failure(EtherNodeError.malformedJSON(json))
                return
            }
            
            success(txReceipt)
        }, failure: { error in
            failure(error)
        })
    }
    
    //    func checkTx(creationTx: String) -> Future<
    //    func checkTx(creationTx: String, success: () -> Void, failure: (Error) -> Void) {
    //
    //    }
}

struct TxReceipt {
    let blockNumber: String
    let gasUsed: String
    let contractAddress: String
    
    init?(json: JSON) {
        guard let blockNumber = json["blockNumber"].string,
            let gasUsed = json["gasUsed"].string,
            let contractAddress = json["contractAddress"].string else { return nil }
        
        self.blockNumber = blockNumber
        self.gasUsed = gasUsed
        self.contractAddress  = contractAddress
    }
    
}
