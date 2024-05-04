//
//  ContentView.swift
//  StepTracker
//
//  Created by Filip Cernov on 30/04/2024.
//

import SwiftUI
import Charts

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    var body: some View {
        VStack {
            HStack {
                Picker("", selection: $viewModel.selectedTab) {
                    Text(Tabs.today.rawValue)
                        .tag(Tabs.today)
                    Text(Tabs.history.rawValue)
                        .tag(Tabs.history)
                }
                .pickerStyle(.segmented)
                .frame(width: viewModel.constants.pickerWidth)
                Spacer()
            }
            .padding(.leading, viewModel.constants.pickerContainerLeadingPadding)
            Spacer()
            if viewModel.selectedTab == .today {
                if !viewModel.stepCountsPerHour.isEmpty {
                    ZStack {
                        TodayView(stepCountsPerHour: viewModel.stepCountsPerHour,
                                  percentOfCompletedSteps: viewModel.getPercentOfCompletedSteps(),
                                  totalNumberOfCompletedStepsDuringTheDay: viewModel.totalNumberOfCompletedStepsDuringTheDay,
                                  targetedNumberOfSteps: viewModel.targetedNumberOfSteps)
                        if viewModel.dataForTodayAreBeingRefreshed {
                            ProgressView()
                        } else {
                            EmptyView()
                        }
                    }
                } else {
                    ProgressView()
                }
            } else {
                HistoryView(bearerToken: viewModel.bearerToken)
            }
            Spacer()
        }
        .padding(.top, viewModel.constants.containerTopPadding)
        .onAppear {
            Task {
                await viewModel.requestHealthDataAuthorizationAndQueryDailyStepCount()
            }
        }
        .onChange(of: viewModel.newStepsDataForTodayHasBeenFetchedFromHealthKit) {
            Task {
                await viewModel.postHourlyActivityForToday()
            }
        }
    }
}

#Preview {
    ContentView()
}
