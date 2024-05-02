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
        if viewModel.totalNumberOfStepsDuringTheDay == 0 {
            ProgressView()
        } else {
            VStack {
                Text("\(viewModel.totalNumberOfStepsDuringTheDay)")
                    .foregroundStyle(.black)
                    .font(.largeTitle)
                Text("Steps")
                ProgressBar(percent: CGFloat(viewModel.getPercentOfCompletedSteps()))
                HStack {
                    Spacer()
                    Text("\(viewModel.targetNumberOfSteps) Steps")
                        .padding(.trailing, 45)
                }
                Chart(viewModel.stepCountsPerHour, id: \.date) { hour in
                  BarMark(
                    x: .value("Hour", hour.date),
                    y: .value("Steps", hour.stepCount)
                  )
                }
                .chartScrollableAxes(.horizontal)
            }
        }
    }
}

#Preview {
    TodayView()
}
