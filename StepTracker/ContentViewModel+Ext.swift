//
//  ContentViewModel+Ext.swift
//  StepTracker
//
//  Created by Filip Cernov on 03/05/2024.
//

import Foundation

extension ContentViewModel {
    func fetchBearerToken() async {
        let authURL = URL(string: "https://testapi.mindware.us/auth/local")!
        let authData = ["identifier": "user1@test.com", "password": "Test123!"]
        
        var request = URLRequest(url: authURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: authData)
        } catch {
            print("Error encoding auth data: \(error.localizedDescription)")
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Error response: \(response.debugDescription)")
                return
            }
            if let token = try? JSONDecoder().decode(TokenResponse.self, from: data) {
                self.bearerToken = token.jwt
            } else {
                print("Failed to decode token")
            }
        } catch {
            print("Error fetching bearer token: \(error.localizedDescription)")
        }
    }
    
    func postHourlyActivityData(bearerToken: String) async {
        guard !bearerToken.isEmpty, !stepCountsPerHour.isEmpty else {
            print("Bearer token is empty")
            return
        }
        let stepsURL = URL(string: "https://testapi.mindware.us/steps")!
        
        var hourlyActivityData = [[String: Any]]()
        
        // Convert HourlyActivity array to array of dictionaries
        for activity in stepCountsPerHour {
            let activityDict: [String: Any] = [
                "time": activity.time,
                "steps_count": activity.numberOfSteps
            ]
            hourlyActivityData.append(activityDict)
        }
        
        let stepsData = [
            "username": "qtrang",
            "steps_date": getTodaysShortVersionDate(),
            "steps_datetime": getTodaysLongVersionDate(),
            "steps_count": 0,
            "steps_total_by_day": 0
        ] as [String : Any]
        
        var request = URLRequest(url: stepsURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: stepsData)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let responseString = String(data: data, encoding: .utf8)
                print("Error response: \(responseString ?? "No data")")
                return
            }
            print("Hourly activity data posted successfully.")
        } catch {
            print("Error posting hourly activity data: \(error.localizedDescription)")
        }
    }
    
    func getTodaysShortVersionDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        return dateString
    }
    
    func getTodaysLongVersionDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let dateString = dateFormatter.string(from: Date())
        return dateString
    }
}
