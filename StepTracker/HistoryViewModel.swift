//
//  HistoryViewModel.swift
//  StepTracker
//
//  Created by Filip Cernov on 01/05/2024.
//

import Foundation
import HealthKit
import Charts

enum Periods: String {
    case weekly = "7 Days"
    case monthly = "1 Month"
}


class HistoryViewModel: ObservableObject {
    @Published var selectedPeriod: Periods = .weekly
    @Published var activityForTheWeek = [WeeklyActivity]()
    @Published var activityForTheMonth = [MonthlyActivity]()
    let constants = Constants()
    let bearerToken: String
    let userName: String
    let networkManager: NetworkManager
    init(networkManager: NetworkManager ,bearerToken: String, userName: String) {
        self.bearerToken = bearerToken
        self.userName = userName
        self.networkManager = networkManager
    }
    
    @MainActor
    func fetchAndMapUserStepData() async {
        do {
            let response = try await networkManager.fetchUserStepData(bearerToken: bearerToken, userName: userName)
            mapStepsDataResponce(from: response)
        } catch {
            print("DEBUG: Catching error for fetching user step data")
        }
    }
    
    private func mapStepsDataResponce(from responce: [StepDataResponce]) {
        activityForTheWeek = mapToLastSevenDaysActivity(from: responce)
        activityForTheMonth = mapToMonthlyActivity(from: responce)
        print("Acitvity for the month is \(activityForTheMonth)")
    }
    
    private func mapToLastSevenDaysActivity(from data: [StepDataResponce]) -> [WeeklyActivity] {
        let calendar = Calendar.current
        let today = Date()
        
        // Filter data for the last 7 days
        let lastSevenDaysData = data.filter { response in
            guard let date = DateFormatter.iso8601Full.date(from: response.stepsDate) else {
                print("Failed to parse date from string: \(response.stepsDate)")
                return false
            }
            return calendar.isDate(date, inSameDayAs: today) ||
                   calendar.dateComponents([.day], from: date, to: today).day! < 7
        }
        
        // Group data by day
        var weeklyActivityData = [WeeklyActivity]()
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let dateString = DateFormatter.iso8601Full.string(from: date)
            
            let dailyData = lastSevenDaysData.filter { $0.stepsDate == dateString }
            let totalSteps = dailyData.reduce(0) { $0 + ($1.stepsTotalByDay) }
            
            let dayName = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
            weeklyActivityData.append(WeeklyActivity(dayName: dayName, numberOfSteps: totalSteps))
        }
        
        return weeklyActivityData.reversed() // Reverse the order to get the days in chronological order
    }
    
    private func mapToMonthlyActivity(from response: [StepDataResponce]) -> [MonthlyActivity] {
        // Get the start and end dates of the current month
        let calendar = Calendar.current
        let currentDate = Date()
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return []
        }
        
        // Initialize date formatter
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Filter response data for the current month
        let thisMonthData = response.filter { data in
            guard let dataDate = dateFormatter.date(from: data.stepsDate) else { return false }
            return dataDate >= startOfMonth && dataDate <= endOfMonth
        }
        
        // Map filtered data to MonthlyActivity structs
        return thisMonthData.map { data in
            let dayOfMonth = getDayOfMonth(from: data.stepsDate)
            return MonthlyActivity(date: dayOfMonth, numberOfSteps: data.stepsTotalByDay)
        }
    }

    private func getDayOfMonth(from dateString: String) -> Int {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = dateFormatter.date(from: dateString) else { return 0 }
        
        let calendar = Calendar.current
        let dayOfMonth = calendar.component(.day, from: date)
        return dayOfMonth
    }
}

extension HistoryViewModel {
    struct Constants {
        let dayTitle = "Day"
        let stepsTitle = "Steps"
        let dateTitle = "Date"
        let noDataTitle = "No data"
        let barMarkWidthForSevenDays: MarkDimension = 40
        let barMarkWidthForOneMonth: MarkDimension = 50
        let chartVisibleDomainLengthForSevenDays = 7
        let chartVisibleDomainLengthForOneMonth = 4
    }
}
extension DateFormatter {
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
