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
    func fetchAndParseStepDataForOneMonth() async {
        guard !bearerToken.isEmpty else {
            print("Bearer token is empty")
            return
        }
        let stepsURL = URL(string: "https://testapi.mindware.us/steps?username=\(userName)")!
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
              
                    // Handle decoded response as needed
                    print("decoded response: \(decodedResponse)")
                    self.parseStepsData(stepDataResponce: decodedResponse)
              
            } else {
                let responseString = String(data: data, encoding: .utf8)
                print("Error decoding response: \(responseString ?? "No data")")
            }
        } catch {
            print("Error fetching step data: \(error.localizedDescription)")
        }
    }
    
    func parseStepsData(stepDataResponce: [StepDataResponce]) {
        activityForTheWeek = mapToWeeklyActivity(from: stepDataResponce)
        activityForTheMonth = mapToMonthlyActivity(from: stepDataResponce)
        print("Activity for the week is \(activityForTheWeek)")
        print("Activity for the month is \(activityForTheMonth)")
    }
    
    private func mapToWeeklyActivity(from response: [StepDataResponce]) -> [WeeklyActivity] {
        return response.map { data in
            let dayOfWeek = getDayOfWeek(from: data.stepsDate)
            return WeeklyActivity(dayName: dayOfWeek, numberOfSteps: data.stepsTotalByDay)
        }
    }

    private func mapToMonthlyActivity(from response: [StepDataResponce]) -> [MonthlyActivity] {
        return response.map { data in
            let dayOfMonth = getDayOfMonth(from: data.stepsDate)
            return MonthlyActivity(date: dayOfMonth, numberOfSteps: data.stepsTotalByDay)
        }
    }

    func getDayOfWeek(from dateString: String) -> String {
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

    func getDayOfMonth(from dateString: String) -> Int {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = dateFormatter.date(from: dateString) else { return 0 }
        
        let calendar = Calendar.current
        let dayOfMonth = calendar.component(.day, from: date)
        return dayOfMonth
    }
   
    //MARK: For testing purposes on simulator
    private func generateMockWeeklyStepCount() {
        let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        var activityForTheWeekTemp = [WeeklyActivity]()
        for day in dayNames {
            let activity = WeeklyActivity(dayName: day, numberOfSteps: Int.random(in: 0...10000))
            activityForTheWeekTemp.append(activity)
        }
        activityForTheWeek = activityForTheWeekTemp
    }
    
    //MARK: For testing purposes on simulator
    private func generateMockMonthlyStepCount() {
        var activityForTheMonthTemp = [MonthlyActivity]()
        
        for date in 1...31 {
            let activity = MonthlyActivity(date: date, numberOfSteps: Int.random(in: 0...15000))
            activityForTheMonthTemp.append(activity)
        }
        activityForTheMonth = activityForTheMonthTemp
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
