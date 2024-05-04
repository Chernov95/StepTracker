//
//  HourlyActivity.swift
//  StepTracker
//
//  Created by Filip Cernov on 01/05/2024.
//

import Foundation

struct HourlyActivity: Identifiable {
    let id = UUID()
    let time: String
    let numberOfSteps: Int
}
