//
//  TodayView.swift
//  StepTracker
//
//  Created by Filip Cernov on 30/04/2024.
//

import SwiftUI
import Charts

struct TodayView: View {
    @StateObject private var viewModel = TodayViewModel()
    var body: some View {
        if viewModel.stepCountsPerHour.isEmpty {
            ProgressView()
        } else {
            VStack {
                Text("\(viewModel.totalNumberOfStepsDuringTheDay)")
                    .foregroundStyle(.black)
                    .font(.largeTitle)
                Text(viewModel.constants.stepsTitle)
                ProgressBar(percent: viewModel.getPercentOfCompletedSteps())
                HStack {
                    Spacer()
                    Text("\(viewModel.targetNumberOfSteps) \(viewModel.constants.stepsTitle)")
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
                }
                .padding(.horizontal)
                //                .chartScrollableAxes(.horizontal)
                .frame(alignment: .leading)
            }
        }
    }
}

#Preview {
    TodayView()
}
