//
//  HistoryView.swift
//  StepTracker
//
//  Created by Filip Cernov on 01/05/2024.
//

import SwiftUI
import Charts

struct HistoryView: View {
    @StateObject var viewModel = HistoryViewModel()
    @State private var sevenDaysActivityIsDisplayed = true
    var body: some View {
        VStack {
            HStack {
                getButton(withTitle: "7 Days") {
                    sevenDaysActivityIsDisplayed = true
                    if viewModel.activityForTheWeek.isEmpty {
                        viewModel.queryWeeklyStepCount()
                    }
                }
                .background(sevenDaysActivityIsDisplayed ? Color.blue : Color.white)
                .foregroundColor(sevenDaysActivityIsDisplayed ? Color.white : Color.black)
                getButton(withTitle: "30 Days") {
                    sevenDaysActivityIsDisplayed = false
                    if viewModel.activityForTheMonth.isEmpty {
                        viewModel.queryMonthlyStepCount()
                    }
                }
                .background(sevenDaysActivityIsDisplayed ? Color.white : Color.blue)
                .foregroundColor(sevenDaysActivityIsDisplayed ? Color.black : Color.white)
                Spacer()
            }
            .padding(.leading)
            displayBarChart(for: sevenDaysActivityIsDisplayed ? .weekly : .monthly)
            Spacer()
        }
        .onAppear {
            if sevenDaysActivityIsDisplayed && viewModel.activityForTheWeek.isEmpty   {
                viewModel.queryWeeklyStepCount()
            } else if !sevenDaysActivityIsDisplayed && viewModel.activityForTheMonth.isEmpty {
                viewModel.queryMonthlyStepCount()
            }
        }
    }
    
    private func getButton(withTitle title : String, action: @escaping () -> ()) -> some View {
        Button(action: {
            action()
        }, label: {
            Text(title)
        })
        .frame(width: 70, height: 50)
    }
    
    private func displayBarChart(for barChartType: BarChartType) -> some View {
        if barChartType == .weekly {
            if viewModel.activityForTheWeek.isEmpty {
                return AnyView(ProgressView())
            } else {
                return AnyView(Chart(viewModel.activityForTheWeek, id: \.dayName) { day in
                    BarMark(
                        x: .value("Day", day.dayName),
                        y: .value("Steps", day.numberOfSteps)
                    )
                })
            }
        } else {
            if viewModel.activityForTheMonth.isEmpty {
                return AnyView(ProgressView())
            } else {
                return AnyView(Chart(viewModel.activityForTheMonth, id: \.date) { day in
                    BarMark(
                        x: .value("Date", day.date),
                        y: .value("Steps", day.numberOfSteps)
                    )
                })
            }
        }
    }

    enum BarChartType {
        case weekly, monthly
    }
}

#Preview {
    HistoryView()
}
