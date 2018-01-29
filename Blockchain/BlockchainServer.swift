//
//  TransactionsServer.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 17.04.17.

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

import Alamofire
import Foundation
import SwiftyJSON

/**
 Service to interoperate with the server that would provide all transactions related information
 No UI related information should be received with those calls
 */
public class BlockchainServer {
    struct Constant {
        #if SURILLA
        static let proto = "http://"
        static let site = "surilla.com"
        static let isTestNet = true
        #else
        static let proto = "https://"
        static let site = "teambrella.com"
        static let isTestNet = false
        #endif
        
        static var siteURL: String { return proto + site } // "https://surilla.com"
    }
    
    enum Response {
        case success(JSON, Int64)
        case failure(Error)
    }
    
    var isTestnet: Bool = Constant.isTestNet
    
    private(set)var timestamp: Int64 = 0 {
        didSet {
            log("timestamp updated from \(oldValue) to \(timestamp)", type: .cryptoDetails)
        }
    }
    
    lazy var formatter = BlockchainDateFormatter()
    
    init() {
    }
    
    func initTimestamp(completion:@escaping (Response) -> Void) {
        guard let url = url(string: "me/GetTimestamp") else {
            fatalError("Couldn't create URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        Alamofire.request(request).responseJSON { response in
            switch response.result {
            case .success:
                if let value = response.result.value {
                    log("BlockChain server init timestamp reply: \(value)", type: .cryptoRequests)
                    let result = JSON(value)
                    let status = result["Status"]
                    let timestamp = status["Timestamp"].int64Value
                    self.timestamp = timestamp
                    completion(.success(result, timestamp))
                } else {
                    completion(.failure(TeambrellaErrorFactory.emptyReplyError()))
                    //self.delegate?.server(server: self, failedWithError: nil)
                }
            case .failure(let error):
                completion(.failure(error))
                //                self.delegate?.server(server: self, failedWithError: error)
            }
        }
    }
    
    func initClient(privateKey: String, completion: @escaping (_ success: Bool) -> Void) {
        initTimestamp { [weak self] reply in
            guard let me = self else { return }
            switch reply {
            case .success(_, let timestamp):
                let key = Key(base58String: privateKey, timestamp: timestamp)
                
                let request = me.request(string: "me/InitClient", key: key)
                Alamofire.request(request).responseJSON { response in
                    switch response.result {
                    case .success:
                        if let value = response.result.value {
                            log("init client reply: \(value)", type: .cryptoRequests)
                            let result = JSON(value)
                            if let timestamp = result["Timestamp"].int64 {
                                me.timestamp = timestamp
                            }
                            completion(true)
                        }
                    case .failure(let error):
                        log("error initializing client: \(error)", type: [.error, .cryptoRequests])
                        //                        me.delegate?.server(server: me, failedWithError: error)
                        completion(false)
                    }
                }
                
            default: break
            }
        }
    }
    
    func getUpdates(privateKey: String,
                    lastUpdated: Int64,
                    multisigs: [Multisig],
                    transactions: [Tx],
                    signatures: [TxSignature],
                    completion: @escaping (Response) -> Void) {
        let key = Key(base58String: privateKey, timestamp: timestamp)
        let updateInfo = CryptoServerUpdateInfo(multisigs: multisigs,
                                                transactions: transactions,
                                                signatures: signatures,
                                                lastUpdated: lastUpdated,
                                                formatter: formatter)
        let request = self.request(string: "me/GetUpdates", key: key, updateInfo: updateInfo)
        Alamofire.request(request).responseJSON { [weak self] response in
            guard let me = self else { return }
            
            switch response.result {
            case .success:
                if let value = response.result.value {
                    log("Success getting updates with \(updateInfo)", type: .cryptoDetails)
                    let result = JSON(value)
                    let timestamp = result["Status"]["Timestamp"].int64Value
                    me.timestamp = timestamp
                    let lastUpdated = result["Data"]["LastUpdated"].int64Value
                    completion(.success( result["Data"], lastUpdated))
                    //                    me.delegate?.server(server: me, didReceiveUpdates: result["Data"], updateTime: lastUpdated)
                }
            case .failure(let error):
                completion(.failure(error))
                //                me.delegate?.server(server: me, failedWithError: error)
            }
        }
    }
    
    func postTxExplorer(tx: String,
                        urlString: String,
                        success: @escaping (_ txid: String) -> Void,
                        failure: @escaping () -> Void) {
        let queryPath = "/api/tx/send"
        guard let url = URL(string: urlString + queryPath) else { fatalError() }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue( "application/json, text/plain, * / *", forHTTPHeaderField: "Accept")
        let body: [String: Any] = ["rawTx": tx]
        if let data = try? JSONSerialization.data(withJSONObject: body, options: []) {
            request.httpBody = data
        }
        
        Alamofire.request(request).responseJSON { response in
            switch response.result {
            case.success:
                if let value = response.result.value {
                    let json = JSON(value)
                    if let txid = json.string {
                        success(txid)
                        return
                    }
                }
            default: break
            }
            failure()
        }
    }
    
    func fetch(urlString: String, success: @escaping (_ result: JSON) -> Void, failure: @escaping (Error?) -> Void) {
        guard let url = url(string: urlString) else { fatalError() }
        
        let request = URLRequest(url: url)
        Alamofire.request(request).responseJSON { response in
            switch response.result {
            case .success:
                if let value = response.result.value {
                    let json = JSON(value)
                    success(json)
                    return
                }
            case let .failure(error):
                failure(error)
            }
        }
    }

    func postData(to urlString: String,
                  data: Data,
                  privateKey: String,
                  success: @escaping (_ result: JSON) -> Void,
                  failure: @escaping (Error?) -> Void) {
        guard let url = self.url(string: urlString) else {
            failure(nil)
            return
        }

        let key = Key(base58String: privateKey, timestamp: timestamp)
        //let request: URLRequest = self.postDataRequest(string: urlString, key: key, data: data)
        let application = Application()
        let headers: HTTPHeaders = ["t": "\(timestamp)",
            "key": key.publicKey,
            "sig": key.signature,
            "clientVersion": application.clientVersion,
            "deviceToken": "",
            "deviceId": application.uniqueIdentifier]

        Alamofire.upload(data, to: url, method: .post, headers: headers).responseJSON { response in
            switch response.result {
            case let .success(value):
                let json = JSON(value)
                success(json)
            case let .failure(error):
                failure(error)
            }
        }
    }

    private func request(string: String, key: Key, payload: [String: Any]? = nil) -> URLRequest {
        guard let url = url(string: string) else {
            fatalError("Couldn't create URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue

        let application = Application()
        let dict: [String: Any] = ["t": timestamp,
                                   "key": key.publicKey,
                                   "sig": key.signature,
                                   "clientVersion": application.clientVersion,
                                   "deviceToken": "",
                                   "deviceId": application.uniqueIdentifier]
        for (key, value) in dict {
            request.setValue(String(describing: value), forHTTPHeaderField: key)
        }

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String : Any] = [:]/* ["Timestamp": timestamp,
         "Signature": key.signature,
         "PublicKey": key.publicKey] */
        if let payload = payload {
            for (key, value) in payload {
                body[key] = value
            }
        }
        log("request body: \(body)", type: .cryptoRequests)
        do {
            let data = try JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = data
            log("Request: \(url.absoluteURL)", type: .cryptoRequests)
            return request
        } catch {
            log("could not create data from payload: \(body), error: \(error)", type: [.error, .cryptoRequests])
        }
        fatalError()
    }

    private func request(string: String, key: Key, updateInfo: CryptoServerUpdateInfo) -> URLRequest {
        guard let url = url(string: string) else {
            fatalError("Couldn't create URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue

        let application = Application()
        let dict: [String: Any] = ["t": timestamp,
                                   "key": key.publicKey,
                                   "sig": key.signature,
                                   "clientVersion": application.clientVersion,
                                   "deviceToken": "",
                                   "deviceId": application.uniqueIdentifier]
        for (key, value) in dict {
            request.setValue(String(describing: value), forHTTPHeaderField: key)
        }

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(updateInfo)
            request.httpBody = jsonData
            log("Request: \(url.absoluteURL)", type: .cryptoRequests)
            return request
        } catch {
            log("could not create data from updateInfo: ](updateInfo), error: \(error)", type: [.error, .cryptoRequests])
            fatalError()
        }
    }
    
    /*
     private func postDataRequest(string: String, key: Key, data: Data) -> URLRequest {
     guard let url = url(string: string) else {
     fatalError("Couldn't create URL")
     }

     var request = URLRequest(url: url)
     request.httpMethod = HTTPMethod.post.rawValue
     request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
     let application = Application()
     let dict: [String: Any] = ["t": timestamp,
     "key": key.publicKey,
     "sig": key.signature,
     "clientVersion": application.clientVersion,
     "deviceToken": "",
     "deviceId": application.uniqueIdentifier]
     for (key, value) in dict {
     request.setValue(String(describing: value), forHTTPHeaderField: key)
     }
     request.httpBody = data
     print("Request: \(url.absoluteURL) body: data \(data.count)")
     return request
     }
     */

    private func url(string: String) -> URL? {
        return URL(string: Constant.siteURL + "/" + string)
    }
    
}
