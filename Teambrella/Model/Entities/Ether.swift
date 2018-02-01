//
/* Copyright(C) 2018 Teambrella, Inc.
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

protocol CryptoCurrency: Comparable {
    var value: Double { get }
    var name: String { get }
    var code: String { get }
    var symbol: String { get }

    static var empty: Self { get }

    init(_ value: Double)
}

struct Ether: CryptoCurrency, Decodable, CustomStringConvertible, CustomDebugStringConvertible {
    let value: Double

    let name = "Ethereum"
    let code = "ETH"
    let symbol = "Ξ"

    var description: String { return String(describing: value) }
    var debugDescription: String { return "Ether(\(value)" }

    init(_ value: Double) {
        self.value = value
    }

    init?(string: String?) {
        guard let string = string else { return nil }
        guard let double = Double(string) else { return nil }

        self.value = double
    }

    init(_ mEth: MEth) {
        self.value = mEth.value / 1000
    }

    init(_ gwei: Gwei) {
        self.value = gwei.value * 1_000_000_000
    }

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(Double.self)
        self.value = value
    }

}

extension CryptoCurrency {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.value == rhs.value
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.value < rhs.value
    }

    static var empty: Self { return Self(0) }
}

extension CryptoCurrency {
   prefix static func - (lhs: Self) -> Self {
        return Self(-lhs.value)
    }

    static func + (lhs: Self, rhs: Self) -> Self {
        return Self(lhs.value + rhs.value)
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        return Self(lhs.value - rhs.value)
    }
    
}

struct MEth: CryptoCurrency, Decodable, CustomStringConvertible, CustomDebugStringConvertible {
    let value: Double

    let name = "Finney"
    let code = "mETH"
    let symbol = "mΞ"

    var description: String { return String(describing: value) }
    var debugDescription: String { return "Meth(\(value)" }

    init(_ value: Double) {
        self.value = value
    }

    init?(string: String?) {
        guard let string = string else { return nil }
        guard let double = Double(string) else { return nil }

        self.value = double
    }

    init(_ ether: Ether) {
        self.value = ether.value * 1000
    }

    init(_ gwei: Gwei) {
        self.value = gwei.value * 1000_000
    }

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(Double.self)
        self.value = value
    }

}

struct Gwei: CryptoCurrency, Decodable, CustomStringConvertible, CustomDebugStringConvertible {
    let value: Double

    let name = "Gwei"
    let code = "Gwei"
    let symbol = "Gwei"

    var description: String { return String(describing: value) }
    var debugDescription: String { return "Gwei(\(value)" }

    init(_ value: Double) {
        self.value = value
    }

    init?(string: String?) {
        guard let string = string else { return nil }
        guard let double = Double(string) else { return nil }

        self.value = double
    }

    init(_ mEth: MEth) {
        self.value = mEth.value * 1000
    }

    init(_ ether: Ether) {
        self.value = ether.value * 1_000_000_000
    }

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(Double.self)
        self.value = value
    }

}
