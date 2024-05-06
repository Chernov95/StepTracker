//
//  TodayViewModel.swift
//  StepTracker
//
//  Created by Filip Cernov on 30/04/2024.
//

import Foundation
import HealthKit
import Charts

class TodayViewModel: ObservableObject {
    let constants = Constants()
    let stepCountsPerHour: [HourlyActivity]
    let totalNumberOfCompletedStepsDuringTheDay: Int
    let percentOfCompletedSteps: Int
    let targetedNumberOfSteps: Int

    init(stepCountsPerHour: [HourlyActivity],
         totalNumberOfCompletedStepsDuringTheDay: Int,
         percentOfCompletedSteps: Int,
         targetedNumberOfSteps: Int) {
        self.stepCountsPerHour = stepCountsPerHour
        self.percentOfCompletedSteps = percentOfCompletedSteps
        self.targetedNumberOfSteps = targetedNumberOfSteps
        self.totalNumberOfCompletedStepsDuringTheDay = totalNumberOfCompletedStepsDuringTheDay
    }
}

extension TodayViewModel {
    struct Constants {
        let dayTitle = "Day"
        let stepsTitle = "Steps"
        let hourTitle = "Hour"
        let trailingPaddingForStepsText: CGFloat = 45
        let barMarkWidth: MarkDimension = 50
        let chartVisibleDomainLength = 4
    }
}
