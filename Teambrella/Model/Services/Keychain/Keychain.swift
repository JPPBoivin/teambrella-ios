//
//  Keychain.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 15.08.17.
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
import KeychainAccess
//import SwiftKeychainWrapper

#if TEAMBRELLA
    enum KeychainKey: String {
        case ethPrivateAddress = "teambrella.ethPrivateAddress"
        //case ethPrivateAddressDemo = "teambrella.ethPrivateAddress.demo"
        //case lastUserType = "teambrella.lastUserType"
    }
#else
    enum KeychainKey: String {
        case ethPrivateAddress = "ethPrivateAddress"
        //case ethPrivateAddressDemo = "ethPrivateAddress.demo"
        //case lastUserType = "lastUserType"
    }
#endif

class KeychainService {
    let keychain = Keychain(service: Constant.keychainName)
        .accessibility(.always)

    @discardableResult
    func save(value: String, forKey key: KeychainKey) -> Bool {
        do {
            try keychain
                .synchronizable(true)
                .set(value, key: key.rawValue)
            return true
        } catch {
            print("keychain error: \(error)")
            return false
        }
        /*
         return KeychainWrapper.standard.set(value,
         forKey: key.rawValue,
         withAccessibility: KeychainItemAccessibility.always)
         */
    }
    
    func value(forKey key: KeychainKey) -> String? {
        do {
            return try keychain.getString(key.rawValue)
        } catch {
            print("error getting string from keychain: \(error)")
            return nil
        }
        /*
         return KeychainWrapper.standard.string(forKey: key.rawValue)
         */
    }
    
    @discardableResult
    func removeValue(forKey key: KeychainKey) -> Bool {
        do {
            try keychain.remove(key.rawValue)
            return true
        } catch let error {
            print("error removing item from keychain: \(error)")
            return false
        }
        /*
         return KeychainWrapper.standard.removeObject(forKey: key.rawValue)
         */
    }
    
    func clear() {
        removeValue(forKey: .ethPrivateAddress)
//        removeValue(forKey: .ethPrivateAddressDemo)
//        removeValue(forKey: .lastUserType)
    }

    struct Constant {
        #if TEAMBRELLA
        static let keychainName: String = "com.teambrella.ios.app"
        #else
        static let keychainName = "com.surilla.ios.app"
        #endif
    }

}
