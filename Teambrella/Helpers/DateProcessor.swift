//
//  DateProcessor.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 11.07.17.
//  Copyright © 2017 Yaroslav Pasternak. All rights reserved.
//

import Foundation
import SwiftDate

struct DateProcessor {
    
    func stringInterval(from: Date) -> String {
        return ""
    }
    
    // swiftlint:disable force_try
    func stringFromNow(seconds: Int = 0, minutes: Int = 0, hours: Int = 0, days: Int = 0) -> String {
        let dateInRegion: DateInRegion = DateInRegion()
        let date = dateInRegion - days.days - hours.hours - minutes.minutes - seconds.seconds
        let (colloquial, relevant) = try! date.colloquialSinceNow()
        return colloquial
    }
}
