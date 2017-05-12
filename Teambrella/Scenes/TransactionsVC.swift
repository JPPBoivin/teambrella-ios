//
//  TransactionsVC.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 17.04.17.
//  Copyright © 2017 Yaroslav Pasternak. All rights reserved.
//

import CoreData
import SwiftyJSON
import UIKit

class TransactionsVC: UIViewController {
    
    let teambrella = TeambrellaService()
    var isTransitionNeeded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        teambrella.server.initClient(privateKey: BlockchainServer.Constant.fakePrivateKey)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        teambrella.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func tapInit(_ sender: Any) {
        
    }
    
    @IBAction func tapUpdates(_ sender: Any) {
        isTransitionNeeded = true
        teambrella.update()
    }
    
    @IBAction func tapApprove(_ sender: Any) {
        guard let transactions = teambrella.fetcher.resolvableTransactions else { fatalError() }
        guard let signatures = teambrella.fetcher.signaturesToUpdate else { fatalError() }
        
        print("transactions to approve: \(transactions.count)")
        print("signatures to approve: \(signatures.count)")
        transactions.forEach {
            $0.resolve(when: Date())
        }
        
        teambrella.update()
    }
    
    @IBAction func tapCosigners(_ sender: Any) {
        let request: NSFetchRequest<Cosigner> = Cosigner.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "address.addressValue", ascending: true),
                                   NSSortDescriptor(key: "keyOrderValue", ascending: true)]
        let results = try? teambrella.storage.context.fetch(request)
        results?.forEach { item in
            print(item.description)
        }
    }
    @IBAction func tapGenPrivate(_ sender: Any) {
        let key = Key(base58String: BlockchainServer.Constant.fakePrivateKey, timestamp: teambrella.server.timestamp)
        print("timestamp: \(key.timestamp)\nprivate key: \(key.privateKey)\npublic key: \(key.publicKey)")
        print("signature: \(key.signature)")
        let link = "https://surilla.com/me/ClientLogin?data="
        let data = "{\"Timestamp\":\"\(key.timestamp)\","
            + "\"Signature\":\"\(key.signature)\","
            + "\"PublicKey\":\"\(key.publicKey)\"}"
        print(link + data)
        print("\n\n")
        // urlQueryAllowed doesn't conform to what server is waiting for
        // use https://www.w3schools.com/tags/ref_urlencode.asp
        guard let urlSafeData = data.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            fatalError("Can't create string")
        }
        
        print(link + urlSafeData)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? TransactionsresultTVC {
            vc.teambrella = teambrella
        } else if let vc = segue.destination as? PaymentsTVC {
            vc.teambrella = teambrella
        }
        
    }
    
}

extension TransactionsVC: TeambrellaServiceDelegate {
    func teambrellaDidUpdate(service: TeambrellaService) {
        if isTransitionNeeded {
            isTransitionNeeded = false
            performSegue(withIdentifier: "to transactions result", sender: nil)
        }
    }
}
