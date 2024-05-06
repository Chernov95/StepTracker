//
//  StepDataResponce.swift
//  StepTracker
//
//  Created by Filip Cernov on 03/05/2024.
//

import Foundation


struct StepDataResponce: Codable {
    let id: Int
    let username: String
    let stepsDate: String
    let stepsDatetime: String
    let stepsCount: Int
    var stepsTotalByDay: Int
    let createdDatetime: String?
    let createdAt: String?
    let updatedAt: String?
    let stepsTotal: Int? 

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case stepsDate = "steps_date"
        case stepsDatetime = "steps_datetime"
        case stepsCount = "steps_count"
        case stepsTotalByDay = "steps_total_by_day"
        case createdDatetime = "created_datetime"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case stepsTotal = "steps_total"
    }
}
