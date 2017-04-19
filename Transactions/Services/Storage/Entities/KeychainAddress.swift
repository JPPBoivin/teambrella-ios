//
//  KeychainAddress.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 19.04.17.
//  Copyright © 2017 Yaroslav Pasternak. All rights reserved.
//

import CoreData

class KeychainAddress: NSManagedObject {
    var status: UserAddressStatus {
        return UserAddressStatus(rawValue: Int(rawStatus)) ?? .invalid
    }
}
