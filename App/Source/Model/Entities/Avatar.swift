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

/**
 Avatar is a string address to the user avarar file located on server.
 It differs from photo and can't be used instead of it
 */
struct Avatar: Codable {
    static var none: Avatar { return Avatar("") }
    
    let string: String
    
    // image doesn't originate from our server
    var isForeignImage: Bool { return string.hasPrefix("http") }
    
    var urlString: String {
        if isForeignImage { return string }
        return URLBuilder().avatarURLstring(for: string)
    }
    
    var url: URL? { return URL(string: urlString) }
    
    init(_ string: String) {
        self.string = string
    }

    init(from decoder: Decoder) throws {
        string = try decoder.singleValueContainer().decode(String.self)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(string)
    }

}
