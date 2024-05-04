//
//  StepDataPost.swift
//  StepTracker
//
//  Created by Filip Cernov on 04/05/2024.
//

import Foundation

struct StepDataRequest: Codable {
    let id: Int
    let username: String
    let stepsDate: String
    let stepsDatetime: String
    let stepsCount: Int
    let stepsTotalByDay: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case stepsDate = "steps_date"
        case stepsDatetime = "steps_datetime"
        case stepsCount =  "steps_count"
        case stepsTotalByDay = "steps_total_by_day"
    }
}
