//
//  HistoryView.swift
//  StepTracker
//
//  Created by Filip Cernov on 01/05/2024.
//

import SwiftUI
import Charts

struct HistoryView: View {
    @ObservedObject private var viewModel: HistoryViewModel
    init(bearerToken: String, userName: String) {
        _viewModel = ObservedObject(wrappedValue: HistoryViewModel(bearerToken: bearerToken, userName: userName))
    }
    
    var body: some View {
        VStack {
            HStack {
                Picker("", selection: $viewModel.selectedPeriod) {
                    Text(Periods.weekly.rawValue)
                        .tag(Periods.weekly)
                    Text(Periods.monthly.rawValue)
                        .tag(Periods.monthly)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }
            displayBarChart(for: viewModel.selectedPeriod)
            Spacer()
        }
        .onAppear {
            Task {
                await viewModel.fetchAndMapStepDataForOneMonth()
            }
        }
    }
    
    private func displayBarChart(for selectedPeriod: Periods) -> some View {
        if selectedPeriod == .weekly {
            if viewModel.activityForTheWeek.isEmpty {
                return AnyView(ProgressView())
            } else {
                return AnyView(
                    Chart(viewModel.activityForTheWeek, id: \.dayName) { day in
                        BarMark(
                            x: .value(viewModel.constants.dayTitle, day.dayName),
                            y: .value(viewModel.constants.stepsTitle, day.numberOfSteps),
                            width: viewModel.constants.barMarkWidth
                        )
                        .annotation(position: .top) {
                            Text("\(day.numberOfSteps)")
                        }
                        .foregroundStyle(.blue.gradient)
                    }
                        .chartScrollableAxes(.horizontal)
                        .chartXVisibleDomain(length: viewModel.constants.chartVisibleDomainLength)
                )
            }
        } else {
            if viewModel.activityForTheMonth.isEmpty {
                return AnyView(ProgressView())
            } else {
                return AnyView(Chart(viewModel.activityForTheMonth, id: \.date) { day in
                    BarMark(
                        x: .value(viewModel.constants.dateTitle, day.date),
                        y: .value(viewModel.constants.stepsTitle, day.numberOfSteps),
                        width: viewModel.constants.barMarkWidth
                    )
                    .annotation(position: .top) {
                        Text("\(day.numberOfSteps)")
                    }
                    .foregroundStyle(.blue.gradient)
                }
                    .chartScrollableAxes(.horizontal)
                    .chartXVisibleDomain(length: viewModel.constants.chartVisibleDomainLength)
                )
            }
        }
    }
}

//#Preview {
//    HistoryView()
//}
