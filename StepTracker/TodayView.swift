//
//  TodayView.swift
//  StepTracker
//
//  Created by Filip Cernov on 30/04/2024.
//

import SwiftUI
import Charts

struct TodayView: View {
    private let viewModel: TodayViewModel
    
    init(stepCountsPerHour: [HourlyActivity],
         percentOfCompletedSteps: Int,
         totalNumberOfCompletedStepsDuringTheDay: Int,
         targetedNumberOfSteps: Int) {
        viewModel = TodayViewModel(stepCountsPerHour: stepCountsPerHour,
                                   totalNumberOfCompletedStepsDuringTheDay: totalNumberOfCompletedStepsDuringTheDay, 
                                   percentOfCompletedSteps: percentOfCompletedSteps,
                                   targetedNumberOfSteps: targetedNumberOfSteps)
    }
    
    var body: some View {
        VStack {
            Text("\(viewModel.totalNumberOfCompletedStepsDuringTheDay)")
                .foregroundStyle(.black)
                .font(.largeTitle)
            Text(viewModel.constants.stepsTitle)
            ProgressBar(percent: viewModel.percentOfCompletedSteps)
            HStack {
                Spacer()
                Text("\(viewModel.targetedNumberOfSteps) \(viewModel.constants.stepsTitle)")
                    .padding(.trailing, viewModel.constants.trailingPaddingForStepsText)
            }
            Chart(viewModel.stepCountsPerHour, id: \.time) { hour in
                BarMark(
                    x: .value(viewModel.constants.hourTitle, hour.time),
                    y: .value(viewModel.constants.stepsTitle, hour.numberOfSteps),
                    width: viewModel.constants.barMarkWidth
                )
                .annotation(position: .top) {
                    Text("\(hour.numberOfSteps)")
                }
                .foregroundStyle(.blue.gradient)
            }
            .padding(.horizontal)
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: viewModel.constants.chartVisibleDomainLength)
        }
    }
}

//#Preview {
//    TodayView(stepCountsPerHour: <#T##[HourlyActivity]#>, percentOfCompletedSteps: <#T##Int#>, totalNumberOfCompletedStepsDuringTheDay: <#T##Int#>, targetedNumberOfSteps: <#T##Int#>)
//}
