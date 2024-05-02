//
//  ContentView.swift
//  StepTracker
//
//  Created by Filip Cernov on 30/04/2024.
//

import SwiftUI
import Charts

struct ContentView: View {
    @State var todayButtonIsSelected = true

    var body: some View {
        VStack {
            VStack {
                HStack {
                        Button("Today") {
                            todayButtonIsSelected = true
                        }
                        .padding()
                        .background(todayButtonIsSelected ? Color.blue : Color.white)
                        .foregroundColor(todayButtonIsSelected ? Color.white : Color.black)
                        Button("History") {
                            todayButtonIsSelected = false
                        }
                        .padding()
                        .background(!todayButtonIsSelected ? Color.blue : Color.white)
                        .foregroundColor(!todayButtonIsSelected ? Color.white : Color.black)
                    Spacer()
                }
                .padding(.leading, 10)
                Spacer()
                if todayButtonIsSelected {
                    TodayView()
                } else {
                    HistoryView()
                }
                Spacer()
            }
        }
        .padding(.top, 50)
    }
    
    
}

#Preview {
    ContentView()
}
