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
                .disabled(viewModel.bearerToken == nil || viewModel.dataForTodayAreBeingFetchedFromHealthKit == true)
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
        .onChange(of: viewModel.newStepsDataForTodayHasBeenFetchedFromHealthKit) {_, hasBeenFethced in
            if hasBeenFethced {
                Task {
                    if viewModel.bearerToken == nil {
                        await viewModel.fetchBearerToken()
                    }
                    //MARK: This function might return nil when we fail to determine if steps data should be updated in backend. That's why there is if and else if statements
                    await viewModel.getInformationIfStepsDataForTodayIsInBackendAndItHasToBeUpdated()
                    if viewModel.backEndHasToBeUpdatedWithTodaysActivity == true {
                        await viewModel.updateTotalStepsCountForTodayInBackend()
                        CacheManager.shared.updateStepsInCache(newNumberOfStepsToday: viewModel.totalNumberOfCompletedStepsDuringTheDay)
                    } else if viewModel.backEndHasToBeUpdatedWithTodaysActivity == false {
                        await viewModel.postNumberOfStepsForToday()
                    }
                    viewModel.newStepsDataForTodayHasBeenFetchedFromHealthKit = false
                }
            }
        }
        .onReceive(viewModel.timer) { _ in
            print("20 seconds passed")
            if viewModel.healthDataAuthorizationHasBeenGranted && viewModel.selectedTab == .today && !viewModel.dataForTodayAreBeingFetchedFromHealthKit {
                viewModel.queryAndDisplayFreshDailyStepCountFromHealthKit()
            }
        }
    }
}

#Preview {
    ContentView()
}
