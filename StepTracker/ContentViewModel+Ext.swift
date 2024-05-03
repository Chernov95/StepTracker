//
//  ContentViewModel+Ext.swift
//  StepTracker
//
//  Created by Filip Cernov on 03/05/2024.
//

import Foundation

extension ContentViewModel {
    func fetchBearerToken() {
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
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print("No data returned: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                if let token = try? JSONDecoder().decode(TokenResponse.self, from: data) {
                    DispatchQueue.main.async {
                        self.bearerToken = token.jwt
                    }
                    
                }
            } else {
                print("Error response: \(response.debugDescription)")
            }
        }.resume()
    }
    
    func postStepsData() {
        let stepsURL = URL(string: "https://testapi.mindware.us/steps")!
        
        let stepsData = [
            "username": "pylyp",
            "steps_date": "string",
            "steps_datetime": "Unknown Type: datetime",
            "steps_count": 103232,
            "steps_total_by_day": 0
        ] as [String : Any]
        
        var request = URLRequest(url: stepsURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: stepsData)
        } catch {
            print("Error encoding steps data: \(error.localizedDescription)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print("No data returned: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                print("Steps data posted successfully.")
            } else {
                let responseData = data
                let responseString = String(data: responseData, encoding: .utf8)
                print("Error response: \(responseString ?? "No data")")
                
            }
        }.resume()
    }
    
    struct TokenResponse: Codable {
        let jwt: String
    }
}
