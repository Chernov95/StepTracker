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
    let constants = Constants()
    let bearerToken: String
    let userName: String
    var activityForTheMonth = [MonthlyActivity]()
    init(bearerToken: String, userName: String) {
        self.bearerToken = bearerToken
        self.userName = userName
    }
    
    @MainActor
    func fetchAndMapStepDataForOneMonth() async {
        guard let stepsURL = URL(string: "https://testapi.mindware.us/steps?username=\(userName)") else {
            print("Invalid url for fetching users activity")
            return
        }
        var request = URLRequest(url: stepsURL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let responseString = String(data: data, encoding: .utf8)
                print("Error response: \(responseString ?? "No data")")
                return
            }
            if let decodedResponse = try? JSONDecoder().decode([StepDataResponce].self, from: data) {
                print("decoded responce is \(decodedResponse)")
                self.mapStepsDataResponce(from: decodedResponse)
                
            } else {
                let responseString = String(data: data, encoding: .utf8)
                print("Error decoding response: \(responseString ?? "No data")")
            }
        } catch {
            print("Error fetching step data: \(error.localizedDescription)")
        }
    }
    
   private func mapStepsDataResponce(from responce: [StepDataResponce]) {
       activityForTheWeek = mapToWeeklyActivity(from: responce)
        activityForTheMonth = mapToMonthlyActivity(from: responce)
        print("Activity for the week is \(activityForTheWeek)")
        print("Activity for the month is \(activityForTheMonth)")
    }
    
    func mapToWeeklyActivity(from response: [StepDataResponce]) -> [WeeklyActivity] {
        // Get the start and end dates of the current week
        let calendar = Calendar.current
        let currentDate = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate))!
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Filter response data for the current week
        let thisWeekData = response.filter { data in
            guard let dataDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: dateFormatter.date(from: data.stepsDate)!)) else { return false }
            return dataDate >= startOfWeek && dataDate <= endOfWeek
        }
        
        return thisWeekData.map { data in
            let dayOfWeek = getDayOfWeek(from: data.stepsDate)
            return WeeklyActivity(dayName: dayOfWeek, numberOfSteps: data.stepsTotalByDay)
        }
    }
    
    private func mapToMonthlyActivity(from response: [StepDataResponce]) -> [MonthlyActivity] {
        // Get the start and end dates of the current month
        let calendar = Calendar.current
        let currentDate = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
        guard let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
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

    private func getDayOfWeek(from dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = dateFormatter.date(from: dateString) else { return "" }
        
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        switch weekday {
        case 1:
            return "Sun"
        case 2:
            return "Mon"
        case 3:
            return "Tue"
        case 4:
            return "Wed"
        case 5:
            return "Thu"
        case 6:
            return "Fri"
        case 7:
            return "Sat"
        default:
            return ""
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
        let barMarkWidth: MarkDimension = 50
        let chartVisibleDomainLength = 4
    }
}
