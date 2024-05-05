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
    
    func postNumberOfStepsForToday() async {
        guard let bearerToken else {
            print("Bearer token is empty")
            return
        }
        guard !stepCountsPerHour.isEmpty else {
            print("There is no data for posting activity")
            return
        }
        guard let stepsURL = URL(string: "https://testapi.mindware.us/steps") else {
            print("invalid url for posting daily activity")
            return
        }
        
        let stepsData = [
            "username": userName,
            "steps_date": getTodaysShortVersionDate(),
            "steps_datetime": getTodaysLongVersionDate(),
            "steps_count": 0,
            "steps_total_by_day": totalNumberOfCompletedStepsDuringTheDay
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
    
    // Returns true when there is data for steps for today and total number of steps is different from the device.
    // Returns false when there is no data in backend and new data has to be uploaded.
    // Retuns nil when failing to determine
    func thereIsStepsDataForTodayInBackendAndTheyHaveToBeUpdated() async -> Bool? {
        guard let bearerToken else {
            print("Bearer token is empty")
            return nil
        }
        guard let stepsURL = URL(string: "https://testapi.mindware.us/steps?username=\(userName)&steps_date=\(getTodaysShortVersionDate())") else {
            print("Failed to get url for checking steps data for today")
            return nil
        }
        var request = URLRequest(url: stepsURL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let responseString = String(data: data, encoding: .utf8)
                print("Error response for getting id for today's steps data in back end: \(responseString ?? "No data")")
                return nil
            }
            
            if let decodedResponse = try? JSONDecoder().decode([StepDataResponce].self, from: data) {
                if decodedResponse.isEmpty {
                    print("Decoded responce is empty. Data for today's should be postet")
                    return false
                } else if decodedResponse.count > 1 {
                    print("Back end has more data on back for today then required")
                    return nil
                } else {
                    if decodedResponse.first?.stepsTotalByDay  == totalNumberOfCompletedStepsDuringTheDay {
                        print("Total number of steps is the same in backend as on device. Therefore, no need in posting new data. In back end it's \(decodedResponse.first?.stepsTotalByDay) and locally we have \(totalNumberOfCompletedStepsDuringTheDay). Returning nil.")
                        return nil
                    } else {
                        print("Health data on device is different from back end. Backend has to be updated, locally we have total numberOfSteps \(totalNumberOfCompletedStepsDuringTheDay), whereas back end has \(decodedResponse.first?.stepsTotalByDay)")
                        self.idOfStepsDataForTodayInBackend = decodedResponse.first?.id
                        return true
                    }
                }
            } else {
                let responseString = String(data: data, encoding: .utf8)
                print("Error decoding response: \(responseString ?? "No data")")
            }
        } catch {
            print("Error fetching step data: \(error.localizedDescription)")
        }
        return nil
    }
    
    func updateTotalStepsCountForTodayInBackend() async {
        guard let idOfStepsDataForTodayInBackend else {
            print("IdOfTodayStepsDataInBackEnd is nil")
            return
        }
        guard let bearerToken else {
            print("Bearer token is nil")
            return
        }
        guard !stepCountsPerHour.isEmpty else {
            print("Steps data are empty")
            return
        }
        guard let stepsURL = URL(string: "https://testapi.mindware.us/steps/\(idOfStepsDataForTodayInBackend)") else {
            print("invalid url for posting daily activity")
            return
        }
        
        let stepsData = [
            "username": userName,
            "steps_date": getTodaysShortVersionDate(),
            "steps_datetime": getTodaysLongVersionDate(),
            "steps_count": 0,
            "steps_total_by_day": totalNumberOfCompletedStepsDuringTheDay
        ] as [String : Any]
        
        var request = URLRequest(url: stepsURL)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: stepsData)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let responseString = String(data: data, encoding: .utf8)
                print("Error response for updating value in back end: \(responseString ?? "No data")")
                return
            }
            print("Total number of steps in backend have been updated")
        } catch {
            print("Error posting hourly activity data: \(error.localizedDescription)")
        }
    }
    
    private func getTodaysShortVersionDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        return dateString
    }
    
    private func getTodaysLongVersionDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let dateString = dateFormatter.string(from: Date())
        return dateString
    }
}
