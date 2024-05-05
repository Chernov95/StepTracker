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
                        if viewModel.dataForTodayAreBeingFetchedFromHealthKit {
                            ProgressView()
                        } else {
                            EmptyView()
                        }
                    }
                } else {
                    ProgressView()
                }
            } else {
                if let bearerToken = viewModel.bearerToken {
                    HistoryView(bearerToken: bearerToken, userName: viewModel.userName)
                }
            }
            Spacer()
        }
        .padding(.top, viewModel.constants.containerTopPadding)
        .onAppear {
            Task {
                await viewModel.requestHealthDataAuthorization()
            }
        }
        .onChange(of: viewModel.healthDataAuthorizationHasBeenGranted) {_, isGranted in
            if isGranted {
                viewModel.queryAndDisplayFreshDailyStepCountFromHealthKit()
            }
        }
        .onChange(of: viewModel.newStepsDataForTodayHasBeenFetchedFromHealthKit) {
            Task {
                // Check if there is something for today date
                // If there is any, make put request otherwise upload a new data
                // Update back end only for the current day and if there
                await viewModel.fetchBearerToken()
                let thereIsStepsDataForTodayInBackend = await viewModel.thereIsStepsDataForTodayInBackendAndTheyHaveToBeUpdated()
                if thereIsStepsDataForTodayInBackend == true {
                    await viewModel.updateTotalStepsCountForTodayInBackend()
                } else if thereIsStepsDataForTodayInBackend == false {
                    await viewModel.postNumberOfStepsForToday()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
