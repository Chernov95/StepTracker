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
                .disabled(viewModel.bearerToken == nil)
                Spacer()
            }
            .padding(.leading, viewModel.constants.pickerContainerLeadingPadding)
            Spacer()
            if viewModel.selectedTab == .today {
                if !viewModel.hourlyActivityData.isEmpty {
                    ZStack {
                        TodayView(stepCountsPerHour: viewModel.hourlyActivityData,
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
                    HistoryView(networkManager: viewModel.networkManager, bearerToken: bearerToken, userName: viewModel.userName)
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
                await viewModel.fetchBearerToken()
                await viewModel.getInformationIfStepsDataForTodayIsInBackendAndItHasToBeUpdated()
                if viewModel.backEndHasToBeUpdatedWithTodaysActivity == true {
                    await viewModel.updateTotalStepsCountForTodayInBackend()
                } else if viewModel.backEndHasToBeUpdatedWithTodaysActivity == false {
                    await viewModel.postNumberOfStepsForToday()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
